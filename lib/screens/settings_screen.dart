import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('レート制限アラートを有効にする'),
            subtitle: const Text('残りリクエスト数が少なくなったときにアプリ内で通知します'),
            value: _notifyEnabled,
            onChanged: (v) async {
              setState(() => _notifyEnabled = v);
              await _service.setRateLimitNotifyEnabled(v);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('残りリクエストしきい値', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: _minThreshold.toDouble(),
                        max: _maxThreshold.toDouble(),
                        divisions: _maxThreshold - _minThreshold,
                        value: (_threshold.clamp(_minThreshold, _maxThreshold)).toDouble(),
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
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        onFieldSubmitted: (s) async {
                          final parsed = int.tryParse(s) ?? _threshold;
                          final clamped = parsed.clamp(_minThreshold, _maxThreshold);
                          await _applyThreshold(clamped);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('しきい値以下になるとバナーが表示されます（現在: $_threshold）', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('現在の使用量（近似）', style: Theme.of(context).textTheme.titleMedium),
          ),
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: _service.rateLimitNotifier,
            builder: (context, snapshot, _) {
              if (snapshot == null) {
                return const ListTile(
                  title: Text('データ未取得'),
                  subtitle: Text('APIヘッダ情報がまだ取得されていません。操作を実行すると取得されます。'),
                );
              }

              final remaining = snapshot['remaining'];
              final limit = snapshot['limit'];
              final reset = snapshot['reset'];

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: Text('残りリクエスト数: ${remaining ?? "不明"}'),
                    subtitle: Text('上限: ${limit ?? "不明"} / リセット予定: ${reset ?? "不明"}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      value: (remaining is int && limit is int && limit > 0) ? (remaining / limit) : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('注意'),
            subtitle: const Text('表示はサーバーが返すヘッダ情報からの推定値です。実際の残りはサーバー側で変化します。'),
          ),
        ],
      ),
    );
  }
}
