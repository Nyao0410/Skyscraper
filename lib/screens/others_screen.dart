import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../services/bluesky_service.dart';
import '../services/locale_controller.dart';
import '../services/font_controller.dart';
import '../services/theme_controller.dart';
import '../themes/line_theme.dart';
import 'drafts_screen.dart';
import 'profile_screen.dart';
import 'general/language_screen.dart';
import 'general/font_size_screen.dart';
import 'general/theme_screen.dart';
import 'general/storage_screen.dart';

class OthersScreen extends StatefulWidget {
  const OthersScreen({super.key});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
  final _service = BlueskyService();
  // listen to controllers so we can update the subtitles dynamically
  @override
  void initState() {
    super.initState();
    LocaleController.locale.addListener(_onPrefsChanged);
    FontController.fontScale.addListener(_onPrefsChanged);
    ThemeController.mode.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    LocaleController.locale.removeListener(_onPrefsChanged);
    FontController.fontScale.removeListener(_onPrefsChanged);
    ThemeController.mode.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 1,
        shadowColor: theme.shadowColor,
        title: Text(
          AppLocalizations.of(context).others_title,
          style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildAccountSection(accounts),
                const SizedBox(height: 16),
                _buildGeneralSection(),
                const SizedBox(height: 16),
                _buildAppSection(),
                const SizedBox(height: 16),
                _buildSupportSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountSection(List<Map<String, dynamic>> accounts) {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      l10n.others_account,
      [
        // Current Profile
        SettingsItem(
          icon: Icons.person,
          title: l10n.home_my_profile,
          subtitle: _service.handle ?? l10n.user,
          onTap: () {
            if (_service.did != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(actor: _service.did!)),
              );
            }
          },
        ),
        // Account Switching
        if (accounts.length > 1)
          ...accounts
              .where((a) => a['did'] != _service.did)
              .map((account) => SettingsItem(
                    icon: Icons.switch_account,
                    title: l10n.others_switch_account,
                    subtitle: account['handle'] ?? '',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await _service.switchAccount(account['did']);
                      if (mounted) {
                        navigator.pushNamedAndRemoveUntil(
                            '/', (route) => false);
                      }
                    },
                  )),
        SettingsItem(
          icon: Icons.person_add_alt_1,
          title: l10n.addAccount,
          subtitle: '',
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        SettingsItem(
          icon: Icons.logout,
          title: l10n.others_logout,
          subtitle: '',
          titleColor: LineColors.error,
          showArrow: false,
          onTap: () async {
            final navigator = Navigator.of(context);
            await _service.logout();
            if (mounted) {
              final remaining = await _service.getAccounts();
              if (remaining.isEmpty) {
                navigator.pushReplacementNamed('/login');
              } else {
                await _service.switchAccount(remaining.first['did']);
                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    final l10n = AppLocalizations.of(context);
    // Determine dynamic subtitles from controllers
    // Language
    final loc = LocaleController.locale.value ?? Localizations.localeOf(context);
    final langCode = loc.languageCode;
    final languageSubtitle = langCode == 'ja' ? l10n.language_japanese : l10n.language_english;

    // Font size mapping
    final scale = FontController.fontScale.value;
    String fontSubtitle;
    if (scale <= 0.85) {
      fontSubtitle = l10n.font_size_small;
    } else if (scale <= 1.1) {
      fontSubtitle = l10n.font_size_medium;
    } else if (scale <= 1.25) {
      fontSubtitle = l10n.font_size_large;
    } else {
      fontSubtitle = l10n.font_size_extra_large;
    }

    // Theme mapping
    final mode = ThemeController.mode.value;
    final themeSubtitle = mode == ThemeMode.light
        ? l10n.theme_light
        : mode == ThemeMode.dark
            ? l10n.theme_dark
            : l10n.theme_system;

    return _buildSection(
      l10n.others_general,
      [
        SettingsItem(
          icon: Icons.language,
          title: l10n.others_language,
          subtitle: languageSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LanguageScreen()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.text_fields,
          // show as just "Font" in the menu (localized)
          title: l10n.others_font_size,
          subtitle: fontSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FontSizeScreen()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.palette,
          title: l10n.others_theme,
          subtitle: themeSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThemeScreen()),
            );
          },
        ),
        SettingsItem(
          icon: Icons.storage,
          title: l10n.others_storage,
          subtitle: l10n.storage_cache_desc,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StorageScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      l10n.others_app_settings,
      [
        SettingsItem(
          icon: Icons.edit_note,
          title: l10n.others_drafts,
          subtitle: l10n.draftsSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DraftsScreen()),
            );
          },
        ),
        // Advanced settings removed per user request
      ],
    );
  }

  Widget _buildSupportSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      l10n.others_support,
      [
        SettingsItem(
          icon: Icons.info_outline,
          title: l10n.appInfo,
          subtitle: l10n.version_label('0.1.0'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) Divider(height: 1, color: theme.dividerColor),
                item,
              ],
            );
          }),
        ],
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final bool showArrow;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                // use theme divider/icon color for small chevron
                color: theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
