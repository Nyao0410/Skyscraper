import 'package:flutter/material.dart';
import '../../flutter_gen/gen_l10n/app_localizations.dart';
// Use ThemeData instead of fixed LineColors/LineTextStyles
import '../../services/font_controller.dart';

class FontSizeScreen extends StatefulWidget {
  const FontSizeScreen({super.key});

  @override
  State<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends State<FontSizeScreen> {
  double _fontSize = 1.0; // 1.0 is standard

  @override
  void initState() {
    super.initState();
    _fontSize = FontController.fontScale.value;
    FontController.fontScale.addListener(_onFontChanged);
  }

  @override
  void dispose() {
    FontController.fontScale.removeListener(_onFontChanged);
    super.dispose();
  }

  void _onFontChanged() {
    if (mounted) setState(() => _fontSize = FontController.fontScale.value);
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
        title: Text(AppLocalizations.of(context).fontSize, style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      AppLocalizations.of(context).fontSizePreview,
                      style: TextStyle(
                        fontSize: 16 * _fontSize,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context).fontSizeSmall, style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) async {
                          setState(() {
                            _fontSize = value;
                          });
                          await FontController.setScale(value);
                        },
                      ),
                    ),
                    Text(AppLocalizations.of(context).fontSizeLarge, style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context).fontSizeNote,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
