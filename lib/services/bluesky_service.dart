import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart';
import 'package:bluesky/atproto.dart';
import 'package:atproto_core/atproto_core.dart';

import '../models/post_item.dart';

class BlueskyService {
  Bluesky? _bluesky;
  String? handle;
  String? did;

  bool get isLoggedIn => _bluesky != null;

  Future<void> login(String inputHandle, String password) async {
    try {
      // If user did not include a domain, append .bsky.social
      final normalized = inputHandle.contains('.')
          ? inputHandle
          : '$inputHandle.bsky.social';

      // Create session using Bluesky SDK
      final sessionResponse = await createSession(
        service: 'bsky.social',
        identifier: normalized,
        password: password,
      );
      final session = sessionResponse.data;

      // Initialize Bluesky client with session
      _bluesky = Bluesky.fromSession(session);

      handle = session.handle;
      did = session.did;
      debugPrint('Login successful. Handle: ${handle ?? "null"}, DID: ${did ?? "null"}');
    } on UnauthorizedException catch (e) {
      throw Exception('ログイン失敗: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API エラー: ${e.toString()}');
    } catch (e) {
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }

  Future<List<PostItem>> getTimeline({int limit = 40}) async {
    if (_bluesky == null) {
      throw Exception('ログインしていません');
    }

    try {
      debugPrint('Fetching timeline for handle: ${handle ?? "unknown"} (limit: $limit)...');
      debugPrint('Session DID: ${_bluesky?.session?.did ?? "null"}');
      
      final response = await _bluesky!.feed.getTimeline(limit: limit);
      // debugPrint('Response status: ${response.status.code}');
      
      final feedItems = response.data.feed;
      // debugPrint('Raw feed items count: ${feedItems.length}');

      if (feedItems.isNotEmpty) {
        final first = feedItems.first;
        // debugPrint('First item type: ${first.runtimeType}');
        try {
          // debugPrint('First item post CID: ${first.post.cid}');
          // debugPrint('First item author: ${first.post.author.handle}');
          // debugPrint('First item record type: ${first.post.record.runtimeType}');
        } catch (e) {
          // debugPrint('Error accessing first item properties: ${e.toString()}');
        }
      } else {
        // debugPrint('Timeline is empty from server. Check if the account has follows/posts.');
      }

      final posts = feedItems
          .map((f) {
            try {
              if (f == null) return null;
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              // debugPrint('Error parsing post item: ${e.toString()}');
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
      
      // debugPrint('Successfully parsed ${posts.length} posts');
      return posts;
    } on UnauthorizedException catch (e) {
      throw Exception('認証エラー: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('タイムライン取得失敗: ${e.toString()}');
    } catch (e) {
      debugPrint('Unexpected error in getTimeline: ${e.toString()}');
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }

  Future<void> post(String text) async {
    if (_bluesky == null) throw Exception('ログインしていません');

    if (text.trim().isEmpty) {
      throw Exception('投稿内容が空です');
    }

    if (text.length > 300) {
      throw Exception('投稿は300文字以内にしてください');
    }

    try {
      await _bluesky!.feed.post.create(text: text);
    } on UnauthorizedException catch (e) {
      throw Exception('認証エラー: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('投稿失敗: ${e.toString()}');
    } catch (e) {
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }
}
