import 'package:flutter/material.dart';
import '../../services/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../flutter_gen/gen_l10n/app_localizations.dart';
// Theme-aware styling replaces LineColors/LineTextStyles

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String _selectedTheme = 'system'; // system, light, dark
  static const _prefsThemeKey = 'app_theme';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_prefsThemeKey) ?? 'system';
    if (mounted) setState(() => _selectedTheme = t);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(AppLocalizations.of(context).theme, style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildThemeOption(AppLocalizations.of(context).themeSystem, 'system', theme),
          Divider(height: 1, color: theme.dividerColor),
          _buildThemeOption(AppLocalizations.of(context).themeLight, 'light', theme),
          Divider(height: 1, color: theme.dividerColor),
          _buildThemeOption(AppLocalizations.of(context).themeDark, 'dark', theme),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String value, ThemeData theme) {
    final isSelected = _selectedTheme == value;
    return Container(
      color: theme.colorScheme.surface,
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check, color: theme.colorScheme.primary)
            : null,
        onTap: () async {
          setState(() {
            _selectedTheme = value;
          });
          // Use ThemeController to persist and notify the app
          await ThemeController.setTheme(value);
        },
      ),
    );
  }
}
