import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = BlueskyService();
  bool _notifyEnabled = true;
  int _threshold = 10;
  late TextEditingController _thresholdController;

  static const int _minThreshold = 1;
  static const int _maxThreshold = 500;

  @override
  void initState() {
    super.initState();
    _notifyEnabled = _service.rateLimitNotifyEnabled;
    _threshold = _service.rateLimitNotifyThreshold;
    _thresholdController = TextEditingController(text: _threshold.toString());
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _applyThreshold(int value) async {
    final v = value.clamp(_minThreshold, _maxThreshold);
    setState(() {
      _threshold = v;
      _thresholdController.text = _threshold.toString();
    });
    await _service.setRateLimitNotifyThreshold(v);
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        children: [
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: _service.rateLimitNotifier,
            builder: (context, snapshot, _) {
              final remaining = snapshot != null && snapshot['remaining'] is int
                  ? snapshot['remaining'] as int
                  : null;
              return ListTile(
                title: Text(l10n.settings_current_remaining),
                subtitle:
                    Text(remaining != null ? '$remaining' : l10n.settings_fetching),
                trailing: remaining != null && remaining < _threshold
                    ? const Icon(Icons.warning, color: Colors.orange)
                    : null,
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.settings_enable_alert),
            subtitle: Text(l10n.settings_alert_desc),
            value: _notifyEnabled,
            onChanged: (v) async {
              setState(() => _notifyEnabled = v);
              await _service.setRateLimitNotifyEnabled(v);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settings_threshold,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: _minThreshold.toDouble(),
                        max: _maxThreshold.toDouble(),
                        divisions: _maxThreshold - _minThreshold,
                        value: (_threshold.clamp(_minThreshold, _maxThreshold))
                            .toDouble(),
                        label: '$_threshold',
                        onChanged: (v) {
                          setState(() {
                            _threshold = v.round();
                            _thresholdController.text = _threshold.toString();
                          });
                        },
                        onChangeEnd: (v) async {
                          await _applyThreshold(v.round());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                        onFieldSubmitted: (s) async {
                          final parsed = int.tryParse(s) ?? _threshold;
                          final clamped =
                              parsed.clamp(_minThreshold, _maxThreshold);
                          await _applyThreshold(clamped);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.settings_threshold_desc(_threshold),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.settings_usage_approx,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: _service.rateLimitNotifier,
            builder: (context, snapshot, _) {
              if (snapshot == null) {
                return ListTile(
                  title: Text(l10n.settings_no_data),
                  subtitle: Text(l10n.settings_no_data_desc),
                );
              }

              final remaining = snapshot['remaining'];
              final limit = snapshot['limit'];
              final reset = snapshot['reset'];

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: Text(l10n.settings_remaining_label(
                        remaining?.toString() ?? l10n.unknown)),
                    subtitle: Text(l10n.settings_limit_reset_label(
                        limit?.toString() ?? l10n.unknown,
                        reset?.toString() ?? l10n.unknown)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      value: (remaining is int && limit is int && limit > 0)
                          ? (remaining / limit)
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settings_note_title),
            subtitle: Text(l10n.settings_note_desc),
          ),
        ],
      ),
    );
  }
}
