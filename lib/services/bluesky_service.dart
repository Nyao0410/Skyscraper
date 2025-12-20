import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart';
import 'package:bluesky/atproto.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/com_atproto_repo_strongref.dart';
import 'package:bluesky/app_bsky_feed_post.dart';
import 'package:bluesky/app_bsky_embed_record.dart';

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
      final response = await _bluesky!.feed.getTimeline(limit: limit);
      final feedItems = response.data.feed;

      final posts = feedItems
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              debugPrint('Error parsing post: $e');
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
      
      return posts;
    } on UnauthorizedException catch (e) {
      throw Exception('認証エラー: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('タイムライン取得失敗: ${e.toString()}');
    } catch (e) {
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

  Future<void> like(String cid, String uri) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      debugPrint('Attempting like: uri=$uri, cid=$cid');
      await _bluesky!.feed.like.create(
        subject: RepoStrongRef(cid: cid, uri: AtUri.parse(uri)),
      );
    } catch (e) {
      debugPrint('Like error detail: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Null') && errorStr.contains('subtype') && errorStr.contains('String')) {
        // パースエラーの場合でも、リクエスト自体は成功していることが多いため続行
        debugPrint('Caught potential SDK parsing error in like, assuming success');
        return;
      }
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('いいね失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('いいね失敗: $e');
    }
  }

  Future<void> repost(String cid, String uri) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      debugPrint('Attempting repost: uri=$uri, cid=$cid');
      await _bluesky!.feed.repost.create(
        subject: RepoStrongRef(cid: cid, uri: AtUri.parse(uri)),
      );
    } catch (e) {
      debugPrint('Repost error detail: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Null') && errorStr.contains('subtype') && errorStr.contains('String')) {
        debugPrint('Caught potential SDK parsing error in repost, assuming success');
        return;
      }
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('RP失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('RP失敗: $e');
    }
  }

  Future<void> delete(String uri) async {
    if (_bluesky == null || did == null) throw Exception('ログインしていません');
    try {
      final atUri = AtUri.parse(uri);
      final collection = atUri.collection.toString();
      final rkey = atUri.rkey;
      debugPrint('Attempting delete: repo=$did, collection=$collection, rkey=$rkey');
      
      await _bluesky!.atproto.repo.deleteRecord(
        repo: did!, 
        collection: collection,
        rkey: rkey,
      );
    } catch (e) {
      debugPrint('Delete error detail: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Null') && errorStr.contains('subtype') && errorStr.contains('String')) {
        // 削除の場合、パースエラーが出ても実際には消えていることが多い
        debugPrint('Caught potential SDK parsing error in delete, assuming success');
        return;
      }
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('削除失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('削除失敗: $e');
    }
  }

  Future<void> reply(PostItem item, String text) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      await _bluesky!.feed.post.create(
        text: text,
        reply: ReplyRef(
          root: RepoStrongRef(cid: item.id, uri: AtUri.parse(item.uri)),
          parent: RepoStrongRef(cid: item.id, uri: AtUri.parse(item.uri)),
        ),
      );
    } catch (e) {
      debugPrint('Reply error detail: $e');
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('返信失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('返信失敗: $e');
    }
  }

  Future<void> quote(PostItem item, String text) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      await _bluesky!.feed.post.create(
        text: text,
        embed: UFeedPostEmbed.embedRecord(
          data: EmbedRecord(
            record: RepoStrongRef(cid: item.id, uri: AtUri.parse(item.uri)),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Quote error detail: $e');
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('引用失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('引用失敗: $e');
    }
  }
}
