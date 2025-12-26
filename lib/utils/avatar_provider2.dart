import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

ImageProvider? avatarImageProvider2(String? avatar) {
  if (avatar == null || avatar.isEmpty) return null;
  try {
    if (avatar.startsWith('http')) {
      return kIsWeb ? NetworkImage(avatar) : CachedNetworkImageProvider(avatar);
    }

    if (kIsWeb) return NetworkImage(avatar);

    final file = File(avatar);
    if (file.existsSync()) return FileImage(file);

    return kIsWeb ? NetworkImage(avatar) : CachedNetworkImageProvider(avatar);
  } catch (_) {
    return null;
  }
}
