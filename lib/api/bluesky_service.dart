

import 'dart:typed_data';

import 'package:bluesky/bluesky.dart' as bsky;
import 'package:atproto/atproto.dart' as atp;
import 'package:atproto_core/atproto_core.dart' as atp_core;
import 'package:nsid/nsid.dart' as nsid;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/models/post.dart';
import 'package:skyscraper/models/timeline.dart';
import 'package:skyscraper/providers/bluesky_provider.dart';

final blueskyServiceProvider = Provider<BlueskyService>((ref) {
  return BlueskyService(ref.watch(blueskyProvider));
});

class BlueskyService {
  BlueskyService(this._bluesky);
  final bsky.Bluesky _bluesky;

  Future<Timeline> findTimeline({
    String? cursor,
    int? limit,
  }) async {
    final response = await _bluesky.feed.getTimeline(
      cursor: cursor,
      limit: limit,
    );

    final posts = response.data.feed
        .map((feedView) => Post.fromFeedView(feedView))
        .toList();

    return Timeline(
      posts: posts,
      cursor: response.data.cursor,
    );
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

  Future<atp.StrongRef> likePost(String uri, String cid) async {
    final response = await _bluesky.atproto.repo.createRecord(
      collection: nsid.NSID.parse('app.bsky.feed.like'),
      record: {
        'subject': {
          'uri': uri,
          'cid': cid,
        },
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return response.data;
  }

  Future<void> deleteLike(String uri) async {
    await _bluesky.atproto.repo.deleteRecord(uri: atp_core.AtUri.parse(uri));
  }
}

