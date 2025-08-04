
import 'dart:typed_data';

import 'package:bluesky/bluesky.dart' as bsky;
import 'package:atproto/atproto.dart' as atp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/models/post.dart';
import 'package:skyscraper/providers/bluesky_provider.dart';

final blueskyServiceProvider = Provider<BlueskyService>((ref) {
  return BlueskyService(ref.watch(blueskyProvider));
});

class BlueskyService {
  BlueskyService(this._bluesky);
  final bsky.Bluesky _bluesky;

  Future<bsky.Feed> getTimeline({
    String? cursor,
    int? limit,
  }) async {
    final response = await _bluesky.feed.getTimeline(
      cursor: cursor,
      limit: limit,
    );
    return response.data;
  }

  Future<atp.StrongRef> createPost(
    String text, {
    bsky.Embed? embed,
  }) async {
    final response = await _bluesky.feed.post(
      text: text,
      embed: embed,
    );
    return response.data;
  }

  Future<atp.BlobData> uploadBlob(Uint8List bytes) async {
    final response = await _bluesky.atproto.repo.uploadBlob(bytes);
    return response.data;
  }
}
