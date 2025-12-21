import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/bluesky_service.dart';

// 1x1 transparent PNG to use as a safe placeholder when offline or file missing.
final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,
  0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
  0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,
  0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,
  0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,
  0x54,0x78,0x9C,0x63,0x00,0x01,0x00,0x00,
  0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,
  0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,
]);

ImageProvider? avatarImageProvider(String? avatar) {
  if (avatar == null || avatar.isEmpty) return null;

  try {
    // If the value looks like a local file path, prefer it.
    if (!avatar.startsWith('http')) {
      final file = File(avatar);
      if (file.existsSync()) return FileImage(file);
      // If file path provided but missing, return transparent placeholder to avoid network attempts.
      return MemoryImage(_kTransparentImage);
    }

    // For remote URLs: check if we already downloaded it to local manifest and prefer that.
    final local = BlueskyService().getLocalAvatarPathForUrl(avatar);
    if (local != null && local.isNotEmpty) {
      final f = File(local);
      if (f.existsSync()) return FileImage(f);
    }
    // Fallback to network provider.
    return CachedNetworkImageProvider(avatar);
  } catch (_) {
    return MemoryImage(_kTransparentImage);
  }
}
