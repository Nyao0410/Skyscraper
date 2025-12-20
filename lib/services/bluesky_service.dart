import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart';
import 'package:bluesky/atproto.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/com_atproto_repo_strongref.dart';
import 'package:bluesky/app_bsky_feed_post.dart';
import 'package:bluesky/app_bsky_embed_record.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../models/post_item.dart';

class BlueskyService {
  static final BlueskyService _instance = BlueskyService._internal();
  factory BlueskyService() => _instance;
  BlueskyService._internal();

  Bluesky? _bluesky;
  String? handle;
  String? did;

  final _storage = const FlutterSecureStorage();
  static const _sessionKey = 'bsky_session';

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

      // Save session for persistence
      await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

      debugPrint('Login successful. Handle: ${handle ?? "null"}, DID: ${did ?? "null"}');
    } on UnauthorizedException catch (e) {
      throw Exception('ログイン失敗: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API エラー: ${e.toString()}');
    } catch (e) {
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }

  Future<bool> restoreSession() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return false;

      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final session = Session.fromJson(sessionData);

      // Initialize Bluesky client with session
      _bluesky = Bluesky.fromSession(session);
      handle = session.handle;
      did = session.did;

      debugPrint('Session restored. Handle: $handle');
      return true;
    } catch (e) {
      debugPrint('Failed to restore session: $e');
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _bluesky = null;
    handle = null;
    did = null;
    await _storage.delete(key: _sessionKey);
  }

  Future<List<PostItem>> getTimeline({int limit = 40}) async {
    if (_bluesky == null) {
      throw Exception('ログインしていません');
    }

    try {
      debugPrint('Fetching timeline...');
      final response = await _bluesky!.feed.getTimeline(limit: limit);
      final feedItems = response.data.feed;
      debugPrint('Fetched ${feedItems.length} feed items from timeline');

      final posts = feedItems
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              debugPrint('Error parsing post in getTimeline: $e');
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
      
      debugPrint('Parsed ${posts.length} posts from timeline');
      return posts;
    } on UnauthorizedException catch (e) {
      throw Exception('認証エラー: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('タイムライン取得失敗: ${e.toString()}');
    } catch (e) {
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }

  Future<List<PostItem>> getCustomFeed(String feedUri, {int limit = 40}) async {
    if (_bluesky == null) {
      throw Exception('ログインしていません');
    }

    try {
      debugPrint('Fetching custom feed: $feedUri');
      
      final List<dynamic> feedItems;
      if (feedUri == 'following') {
        final response = await _bluesky!.feed.getTimeline(limit: limit);
        feedItems = response.data.feed;
      } else {
        final response = await _bluesky!.feed.getFeed(
          feed: AtUri.parse(feedUri),
          limit: limit,
        );
        feedItems = response.data.feed;
      }
      
      debugPrint('Fetched ${feedItems.length} feed items from $feedUri');

      final posts = feedItems
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              debugPrint('Error parsing post in getCustomFeed: $e');
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
      
      debugPrint('Parsed ${posts.length} posts from $feedUri');
      return posts;
    } on UnauthorizedException catch (e) {
      throw Exception('認証エラー: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('フィード取得失敗: ${e.toString()}');
    } catch (e) {
      throw Exception('ネットワークエラー: ${e.toString()}');
    }
  }

  Future<List<Map<String, String>>> getSavedFeeds() async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      debugPrint('Fetching preferences...');
      final prefsResponse = await _bluesky!.actor.getPreferences();
      final prefs = prefsResponse.data.preferences;

      List<String> savedUris = [];
      for (final pref in prefs) {
        try {
          final json = pref.toJson();
          final type = json[r'$type'] ?? json['\$type'];
          debugPrint('Preference type: $type');

          if (type == 'app.bsky.actor.defs#savedFeedsPref') {
            // V1: pinned and saved
            final pinned = json['pinned'] as List?;
            final saved = json['saved'] as List?;
            if (pinned != null) {
              for (var uri in pinned) savedUris.add(uri.toString());
            }
            if (saved != null) {
              for (var uri in saved) savedUris.add(uri.toString());
            }
          } else if (type == 'app.bsky.actor.defs#savedFeedsPrefV2') {
            // V2: items with pinned flag
            final items = json['items'] as List?;
            if (items != null) {
              for (var item in items) {
                if (item['value'] != null) {
                  savedUris.add(item['value'].toString());
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing preference item: $e');
        }
      }

      // Remove duplicates
      savedUris = savedUris.toSet().toList();

      debugPrint('Saved URIs found: ${savedUris.length}');
      for (var uri in savedUris) {
        debugPrint(' - $uri');
      }

      if (savedUris.isEmpty) {
        return [
          {'name': 'Following', 'uri': 'following', 'desc': 'フォロー中の投稿'},
        ];
      }

      // Filter only app.bsky.feed.generator URIs for getFeedGenerators
      final feedGenUris = savedUris
          .where((uri) => uri.contains('app.bsky.feed.generator'))
          .map((e) => AtUri.parse(e))
          .toList();

      debugPrint('Feed Generator URIs: ${feedGenUris.length}');

      final List<Map<String, String>> result = [];
      result.add({'name': 'Following', 'uri': 'following', 'desc': 'フォロー中の投稿'});

      if (feedGenUris.isNotEmpty) {
        try {
          final generatorsResponse = await _bluesky!.feed.getFeedGenerators(
            feeds: feedGenUris,
          );
          final generators = generatorsResponse.data.feeds;

          for (final gen in generators) {
            result.add({
              'name': gen.displayName,
              'uri': gen.uri.toString(),
              'desc': gen.description ?? '',
              'avatar': gen.avatar ?? '',
              'indexedAt': gen.indexedAt.toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error calling getFeedGenerators: $e');
          // If getFeedGenerators fails, we still have 'Following'
          // and we could potentially add the raw URIs as fallback names
          for (var uri in savedUris) {
            if (uri != 'following' && !result.any((element) => element['uri'] == uri)) {
              result.add({
                'name': 'Unknown Feed',
                'uri': uri,
                'desc': uri,
                'indexedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      }

      // Sort by indexedAt if available
      result.sort((a, b) {
        final timeA = DateTime.tryParse(a['indexedAt'] ?? '') ?? DateTime(0);
        final timeB = DateTime.tryParse(b['indexedAt'] ?? '') ?? DateTime(0);
        return timeB.compareTo(timeA);
      });

      debugPrint('Total feeds to display: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('Error fetching saved feeds: $e');
      return [
        {'name': 'Following', 'uri': 'following', 'desc': 'フォロー中の投稿', 'indexedAt': DateTime.now().toIso8601String()},
      ];
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
      final root = item.replyRoot ?? StrongRef(cid: item.id, uri: item.uri);
      await _bluesky!.feed.post.create(
        text: text,
        reply: ReplyRef(
          root: RepoStrongRef(cid: root.cid, uri: AtUri.parse(root.uri)),
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

  Future<dynamic> getPostThread(String uri) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      final response = await _bluesky!.feed.getPostThread(uri: AtUri.parse(uri));
      return response.data.thread;
    } catch (e) {
      debugPrint('GetThread error detail: $e');
      throw Exception('スレッド取得失敗: $e');
    }
  }

  Future<dynamic> getProfile(String actor) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      final response = await _bluesky!.actor.getProfile(actor: actor);
      return response.data;
    } catch (e) {
      debugPrint('GetProfile error detail: $e');
      throw Exception('プロフィール取得失敗: $e');
    }
  }

  Future<List<PostItem>> getAuthorFeed(String actor, {int limit = 40}) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      final response = await _bluesky!.feed.getAuthorFeed(actor: actor, limit: limit);
      final feedItems = response.data.feed;
      
      return feedItems
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();
    } catch (e) {
      debugPrint('GetAuthorFeed error detail: $e');
      throw Exception('ユーザー投稿取得失敗: $e');
    }
  }

  Future<List<PostItem>> searchPosts(String query, {int limit = 40, String? since, String? until}) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      final response = await _bluesky!.feed.searchPosts(
        query,
        limit: limit,
        since: since,
        until: until,
      );
      final posts = response.data.posts;
      
      return posts.map((p) {
        // searchPosts returns PostView, which we can wrap in a fake FeedView-like structure or handle directly
        // PostItem.fromFeedView expects a FeedView (which has a 'post' field)
        return PostItem.fromFeedView({'post': p.toJson()}, handle);
      }).toList();
    } catch (e) {
      debugPrint('SearchPosts error detail: $e');
      throw Exception('投稿検索失敗: $e');
    }
  }

  Future<List<dynamic>> searchActors(String term, {int limit = 40}) async {
    if (_bluesky == null) throw Exception('ログインしていません');
    try {
      final response = await _bluesky!.actor.searchActors(
        term: term,
        limit: limit,
      );
      return response.data.actors;
    } catch (e) {
      debugPrint('SearchActors error detail: $e');
      throw Exception('ユーザー検索失敗: $e');
    }
  }
}
