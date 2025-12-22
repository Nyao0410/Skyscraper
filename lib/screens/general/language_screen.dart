import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/locale_controller.dart';
import '../../flutter_gen/gen_l10n/app_localizations.dart';
// Theme-based colors used instead of fixed LineColors

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _storedLocale;
  static const _prefsLocaleKey = 'locale';

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsLocaleKey);
    if (mounted) setState(() => _storedLocale = code);
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLocaleKey, code);
    final l = Locale(code);
    await LocaleController.setLocale(l);
    if (mounted) setState(() => _storedLocale = code);
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<Map<String, String>> languages = [
      {'label': l10n.language_japanese, 'code': 'ja'},
      {'label': l10n.language_english, 'code': 'en'},
    ];

    // Use stored preference if available; otherwise fallback to system locale
    // We'll load stored value in initState and store it in _storedLocale
    final currentLocale = _storedLocale ?? Localizations.localeOf(context).languageCode;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 1,
        shadowColor: theme.shadowColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.language_title, style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = lang['code'] == currentLocale;
          return Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    lang['label']!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    // Save selection to SharedPreferences. Actual runtime
                    // locale switching isn't implemented, but we persist the
                    // user's choice for future use.
                    _saveLanguage(lang['code']!);
                  },
                ),
                if (index < languages.length - 1)
                  Divider(height: 1, indent: 16, color: theme.dividerColor),
              ],
            ),
          );
        },
      ),
    );
  }
}
