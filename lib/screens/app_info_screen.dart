import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appInfo),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info?.version ?? '1.0.0';
          final buildNumber = info?.buildNumber ?? '1';

          return ListView(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C300),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Skyscraper',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bluesky Client',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version $version ($buildNumber)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildInfoSection(context, [
                _InfoTile(
                  icon: Icons.description_outlined,
                  title: 'Licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Skyscraper',
                    applicationVersion: version,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ),
                /*_InfoTile(
                  icon: Icons.code,
                  title: 'GitHub Repository',
                  onTap: () => _launchUrl('https://github.com/Nyao0410/bsky_client_beta1'),
                ),
                _InfoTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchUrl('https://github.com/Nyao0410/bsky_client_beta1/blob/main/PRIVACY.md'),
                ),
                */
              ]),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Developed with ❤️ using Flutter',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(
            children: [
              if (index > 0) Divider(height: 1, color: theme.dividerColor),
              child,
            ],
          );
        }).toList(),
      ),
    );
  }

  // keep helper for potential future use (currently referenced in commented code)
  // ignore: unused_element
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
