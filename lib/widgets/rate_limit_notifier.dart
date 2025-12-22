import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';

/// Listens to `BlueskyService.rateLimitNotifier` and shows a MaterialBanner
/// at the top when remaining requests are below the configured threshold.
class RateLimitNotifier extends StatefulWidget {
  final Widget child;
  const RateLimitNotifier({required this.child, super.key});

  @override
  State<RateLimitNotifier> createState() => _RateLimitNotifierState();
}

class _RateLimitNotifierState extends State<RateLimitNotifier> {
  final _service = BlueskyService();
  bool _bannerVisible = false;

  @override
  void initState() {
    super.initState();
    _service.rateLimitNotifier.addListener(_onRateLimitChanged);
  }

  @override
  void dispose() {
    try {
      _service.rateLimitNotifier.removeListener(_onRateLimitChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onRateLimitChanged() {
    final val = _service.rateLimitNotifier.value;
    // Only show banner when feature enabled
    if (!_service.rateLimitNotifyEnabled) {
      if (_bannerVisible) _removeBanner();
      return;
    }

    

    if (val == null) {
      _removeBanner();
      return;
    }

    final rem = val['remaining'];
    final limit = val['limit'];
    final reset = val['reset'];

    if (rem is int && limit is int && rem <= _service.rateLimitNotifyThreshold) {
      _showBanner(rem, limit, reset);
    } else {
      _removeBanner();
    }
  }

  void _showBanner(int remaining, int limit, dynamic reset) {
    if (!mounted) return;
    if (_bannerVisible) return; // already visible

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final resetStr = reset?.toString() ?? l10n.unknown;

    final banner = MaterialBanner(
      content: Text(l10n.rate_limit_banner(remaining, limit, resetStr)),
      leading: const Icon(Icons.warning, color: Colors.orange),
      backgroundColor: Colors.yellow[100],
      actions: [
        TextButton(
          onPressed: () {
            messenger.clearMaterialBanners();
            setState(() => _bannerVisible = false);
          },
          child: Text(l10n.close),
        ),
      ],
    );

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(banner);
    setState(() => _bannerVisible = true);
  }

  void _removeBanner() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.clearMaterialBanners();
    }
    if (_bannerVisible) setState(() => _bannerVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
