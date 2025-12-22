import 'dart:io';
import 'package:flutter/material.dart';
import '../../flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
// Theme aware styles

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String? _cacheSize;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    final l10n = AppLocalizations.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      
      int totalSize = 0;
      
      // Calculate temp dir size
      if (tempDir.existsSync()) {
        await for (final file in tempDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      // Calculate avatar cache in documents (avatar_*)
      if (appDir.existsSync()) {
        await for (final file in appDir.list(recursive: false)) {
          if (file is File && file.path.contains('avatar_')) {
            totalSize += await file.length();
          }
        }
      }

      if (mounted) {
        setState(() {
          _cacheSize = _formatBytes(totalSize);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = l10n.unknown;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _clearCache() async {
    setState(() {
      _isCleaning = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      
      // Re-calculate
      await _calculateCacheSize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).clearCacheMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).clearCacheError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCleaning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(l10n.storage, style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.cacheData, style: theme.textTheme.bodyLarge),
                  subtitle: Text(l10n.cacheDataSubtitle, style: theme.textTheme.bodyMedium),
                  trailing: Text(_cacheSize ?? l10n.storage_calculating, style: theme.textTheme.bodyLarge),
                ),
                Divider(height: 1, indent: 16, color: theme.dividerColor),
                ListTile(
                  title: Text(
                    l10n.clearCache,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                  ),
                  onTap: _isCleaning ? null : () => _showClearConfirmation(context),
                  trailing: _isCleaning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).cacheDescription,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return AlertDialog(
          title: Text(AppLocalizations.of(context).clearCacheConfirmTitle),
          content: Text(AppLocalizations.of(context).clearCacheConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: dialogTheme.colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearCache();
              },
              child: Text(AppLocalizations.of(context).delete, style: TextStyle(color: dialogTheme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}
