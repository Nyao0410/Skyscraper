import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'io_stub.dart' if (dart.library.io) 'dart:io' as io;
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart' show ImageProvider, MemoryImage;
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
    // On web we cannot access local files reliably - use network provider.
    if (kIsWeb) {
      // On web, prefer loading directly from the network. This will work
      // when the avatar CDN provides proper CORS headers. If the request
      // fails (CORS or other network error), fall back to a transparent
      // placeholder to avoid crashing the UI.
      try {
        return NetworkImage(avatar);
      } catch (_) {
        return MemoryImage(_kTransparentImage);
      }
    }

    // If the value looks like a local file path, prefer it on non-web platforms.
    if (!avatar.startsWith('http')) {
      final file = io.File(avatar);
      if (file.existsSync()) return FileImage(file as dynamic);
      return MemoryImage(_kTransparentImage);
    }

    // For remote URLs: check if we already downloaded it to local manifest and prefer that (non-web only).
    final local = BlueskyService().getLocalAvatarPathForUrl(avatar);
    if (local != null && local.isNotEmpty) {
      final f = io.File(local);
      if (f.existsSync()) return FileImage(f as dynamic);
    }

    // Fallback to network provider.
    return CachedNetworkImageProvider(avatar);
  } catch (_) {
    return MemoryImage(_kTransparentImage);
  }
}
