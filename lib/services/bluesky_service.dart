import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/foundation.dart';
import 'package:bluesky/bluesky.dart';
import 'package:bluesky/atproto.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/com_atproto_repo_strongref.dart';
import 'package:bluesky/app_bsky_feed_post.dart';
import 'package:bluesky/app_bsky_embed_record.dart';
import 'package:bluesky/app_bsky_embed_images.dart';
import 'package:bluesky/app_bsky_embed_video.dart';
import 'package:bluesky/app_bsky_embed_recordwithmedia.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:async';

import '../models/post_item.dart';
import 'database_service.dart';

class BlueskyService {
  static final BlueskyService _instance = BlueskyService._internal();
  factory BlueskyService() => _instance;
  BlueskyService._internal();

  Bluesky? _bluesky;
  String? handle;
  String? did;
  String? avatar; // local saved avatar path (file path)
  String? avatarUrl; // original remote avatar URL
  // profile in-memory cache
  final Map<String, dynamic> _profileCache = {}; // actor -> profile data
  // avatar url -> local file path manifest (in-memory)
  final Map<String, String> _avatarManifest = {};

  // TTL durations (recommended defaults)
  static final Duration _ttlTimeline = const Duration(seconds: 60); // 60s
  static final Duration _ttlCustomFeed = const Duration(minutes: 10); // 10min
  static final Duration _ttlProfile = const Duration(days: 1); // 24h

  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService();
  static const _sessionKey = 'bsky_session';
  static const _accountsKey = 'bsky_accounts';
  static const _avatarManifestFile = 'avatar_manifest.json';
  static const int _maxAvatarManifestEntries = 2000;
  static const _rateLimitNotifyEnabledKey = 'bsky_notify_rate_limit';
  static const _rateLimitThresholdKey = 'bsky_rate_limit_threshold';
  static const _rateLimitSnapshotKey = 'bsky_rate_limit_snapshot';
  // Rate limit tracking
  int? rateLimitRemaining;
  int? rateLimitLimit;
  DateTime? rateLimitReset;
  final ValueNotifier<Map<String, dynamic>?> rateLimitNotifier = ValueNotifier(null);
  // whether to show in-app notifications when remaining requests are low
  bool rateLimitNotifyEnabled = true;
  // threshold to trigger in-app notification (absolute remaining requests)
  int rateLimitNotifyThreshold = 10;
  DateTime? _lastRateLimitNotifiedAt;
  static const _rateLimitNotifyCooldown = Duration(minutes: 30);
  DateTime? _rateLimitLastReset;

  bool get isLoggedIn => _bluesky != null;

  Future<void> login(String inputHandle, String password) async {
    try {
      // If we have a current session, make sure it's saved to the accounts list before we overwrite it
      final currentSessionJson = await _storage.read(key: _sessionKey);
      if (currentSessionJson != null) {
        try {
          final session = Session.fromJson(jsonDecode(currentSessionJson));
          await _addAccount(session);
        } catch (e) {
          debugPrint('Failed to save current session before login: $e');
        }
      }

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

      await activateSession(session);

      // Save session for persistence
      await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
      
      // Add to accounts list
      await _addAccount(session);

      debugPrint('Login successful. Handle: ${handle ?? "null"}, DID: ${did ?? "null"}');
    } on UnauthorizedException catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('API Error: ${e.toString()}');
    } catch (e) {
      throw Exception('Network Error: ${e.toString()}');
    }
  }

  Future<void> _saveRateLimitSnapshot() async {
    try {
      // Ensure we have a last-reset timestamp. Normalize it to local midnight
      _rateLimitLastReset ??= DateTime.now();
      final normalizedLastReset = DateTime(
        _rateLimitLastReset!.year,
        _rateLimitLastReset!.month,
        _rateLimitLastReset!.day,
      );

      final map = {
        'remaining': rateLimitRemaining,
        'limit': rateLimitLimit,
        'reset': rateLimitReset?.toIso8601String(),
        // store normalized (midnight) last_reset so that reload can compare by date
        'last_reset': normalizedLastReset.toIso8601String(),
      };

      await _storage.write(key: _rateLimitSnapshotKey, value: jsonEncode(map));
    } catch (e) {
      debugPrint('Failed to save rate limit snapshot: $e');
    }
  }

  Future<void> _loadRateLimitSnapshot() async {
    try {
      final raw = await _storage.read(key: _rateLimitSnapshotKey);
      if (raw == null) return;
      final Map<String, dynamic> m = jsonDecode(raw);

      // Restore basic fields if present
      if (m.containsKey('remaining')) {
        rateLimitRemaining = (m['remaining'] is int) ? m['remaining'] as int : int.tryParse(m['remaining'].toString());
      }
      if (m.containsKey('limit')) {
        rateLimitLimit = (m['limit'] is int) ? m['limit'] as int : int.tryParse(m['limit'].toString());
      }
      if (m.containsKey('reset')) {
        try {
          rateLimitReset = DateTime.parse(m['reset']);
        } catch (_) {}
      }
      if (m.containsKey('last_reset')) {
        try {
          _rateLimitLastReset = DateTime.parse(m['last_reset']);
        } catch (_) {}
      }

      // If last_reset is not today (local date), reset remaining to limit.
      if (rateLimitLimit != null) {
        final now = DateTime.now();
        bool needsReset = false;
        if (_rateLimitLastReset == null) {
          needsReset = true;
        } else {
          final last = DateTime(
            _rateLimitLastReset!.year,
            _rateLimitLastReset!.month,
            _rateLimitLastReset!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (today.isAfter(last)) {
            needsReset = true;
          }
        }

        if (needsReset) {
          // reset remaining to the known limit and mark last reset as today's midnight
          rateLimitRemaining = rateLimitLimit;
          _rateLimitLastReset = DateTime(now.year, now.month, now.day);
          await _saveRateLimitSnapshot();
        }
      }

      // Notify listeners of restored values
      rateLimitNotifier.value = {
        'remaining': rateLimitRemaining,
        'limit': rateLimitLimit,
        'reset': rateLimitReset?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Failed to load rate limit snapshot: $e');
    }
  }

  Future<void> activateSession(Session session) async {
    // Initialize Bluesky client with session
    _bluesky = Bluesky.fromSession(session);

    handle = session.handle;
    did = session.did;

    // Fetch profile to get avatar
    try {
      final profile = await _bluesky!.actor.getProfile(actor: did!);
      final remoteAvatar = profile.data.avatar;
      avatarUrl = remoteAvatar;

      if (remoteAvatar != null && remoteAvatar.isNotEmpty) {
        avatarUrl = remoteAvatar;
        if (!kIsWeb) {
          try {
            final uri = Uri.parse(remoteAvatar);
            final resp = await http.get(uri).timeout(const Duration(seconds: 10));
            if (resp.statusCode == 200) {
              final bytes = resp.bodyBytes;
              final decoded = img.decodeImage(bytes);
              if (decoded != null) {
                // Resize to small width while preserving aspect ratio
                final resized = img.copyResize(decoded, width: 128);
                final jpg = img.encodeJpg(resized, quality: 60);

                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/avatar_${session.did}.jpg');
                await file.writeAsBytes(jpg, flush: true);
                avatar = file.path;
              } else {
                // fallback: save raw bytes
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/avatar_${session.did}');
                await file.writeAsBytes(bytes, flush: true);
                avatar = file.path;
              }
            }
          } catch (e) {
            debugPrint('Avatar download/process failed: $e');
          }
        } else {
          // On web we don't persist avatars to local filesystem; keep remote URL.
          avatar = null;
        }
      } else {
        avatar = null;
      }
    } catch (e) {
      debugPrint('Failed to fetch profile avatar: $e');
    }
    // Load avatar manifest into memory (ensure it's loaded before continuing)
    await _loadAvatarManifest();
    // Load persisted rate-limit notification preference
    try {
      await _loadRateLimitPrefs();
    } catch (_) {}
  }

  Future<void> _loadRateLimitPrefs() async {
    try {
      final v = await _storage.read(key: _rateLimitNotifyEnabledKey);
      if (v == null) return;
      rateLimitNotifyEnabled = (v.toLowerCase() != 'false');
      // also load threshold
      await _loadRateLimitThreshold();
      // also load persisted rate-limit snapshot (remaining/limit/reset/last_reset)
      await _loadRateLimitSnapshot();
    } catch (e) {
      debugPrint('Failed to load rate-limit prefs: $e');
    }
  }

  Future<void> setRateLimitNotifyEnabled(bool enabled) async {
    try {
      rateLimitNotifyEnabled = enabled;
      await _storage.write(key: _rateLimitNotifyEnabledKey, value: enabled ? 'true' : 'false');
    } catch (e) {
      debugPrint('Failed to persist rate-limit notify setting: $e');
    }
  }

  Future<void> _loadRateLimitThreshold() async {
    try {
      final v = await _storage.read(key: _rateLimitThresholdKey);
      if (v == null) return;
      final parsed = int.tryParse(v);
      if (parsed != null && parsed > 0) {
        rateLimitNotifyThreshold = parsed;
      }
    } catch (e) {
      debugPrint('Failed to load rate-limit threshold: $e');
    }
  }

  Future<void> setRateLimitNotifyThreshold(int threshold) async {
    try {
      if (threshold <= 0) return;
      rateLimitNotifyThreshold = threshold;
      await _storage.write(key: _rateLimitThresholdKey, value: threshold.toString());
    } catch (e) {
      debugPrint('Failed to persist rate-limit threshold: $e');
    }
  }

  Future<void> _loadAvatarManifest() async {
    if (kIsWeb) {
      debugPrint('Avatar manifest not supported on web; skipping load');
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_avatarManifestFile');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final Map<String, dynamic> m = jsonDecode(content);
      // Validate entries: keep only those whose files exist
      final Map<String, String> loaded = {};
      for (final entry in m.entries) {
        final k = entry.key;
        final v = entry.value;
        if (v is String) {
          try {
            final f = File(v);
            if (f.existsSync()) {
              loaded[k] = v;
            }
          } catch (_) {}
        }
      }
      _avatarManifest
        ..clear()
        ..addAll(loaded);
      debugPrint('Loaded avatar manifest: ${_avatarManifest.length} entries (validated)');
    } catch (e) {
      debugPrint('Failed to load avatar manifest: $e');
    }
  }

  void _recordRateLimitFromResponse(dynamic respLike) {
    try {
      final headers = _extractHeadersFromResp(respLike);
      if (headers == null || headers.isEmpty) return;
      _updateRateLimitFromHeaders(headers);
    } catch (e) {
      debugPrint('Failed to record rate limit from response: $e');
    }
  }

  Map<String, String>? _extractHeadersFromResp(dynamic r) {
    try {
      // Try several common shapes
      dynamic h;
      if (r == null) return null;
      // r may be an XRPCResponse-like with 'response' property
      try { h = r.response?.headers; } catch (_) {}
      if (h == null) {
        try { h = r.headers; } catch (_) {}
      }
      if (h == null) {
        try { h = r.httpResponse?.headers; } catch (_) {}
      }
      if (h == null) {
        try { h = r.rawResponse?.headers; } catch (_) {}
      }
      if (h == null) return null;

      final Map<String, String> out = {};
      if (h is Map) {
        h.forEach((k, v) {
          try {
            out[k.toString().toLowerCase()] = v.toString();
          } catch (_) {}
        });
      }
      return out;
    } catch (e) {
      return null;
    }
  }

  void _updateRateLimitFromHeaders(Map<String, String> headers) {
    final lower = <String, String>{};
    headers.forEach((k, v) => lower[k.toLowerCase()] = v);

    int? parseInt(String? s) {
      if (s == null) return null;
      try {
        return int.parse(s);
      } catch (_) {
        return null;
      }
    }

    // Common header keys
    final rem = parseInt(lower['x-ratelimit-remaining'] ?? lower['ratelimit-remaining']);
    final limit = parseInt(lower['x-ratelimit-limit'] ?? lower['ratelimit-limit']);
    int? reset = parseInt(lower['x-ratelimit-reset'] ?? lower['ratelimit-reset']);

    // reset may be epoch seconds
    DateTime? resetDt;
    if (reset != null) {
      try {
        if (reset > 1e12) {
          resetDt = DateTime.fromMillisecondsSinceEpoch(reset);
        } else {
          resetDt = DateTime.fromMillisecondsSinceEpoch(reset * 1000);
        }
      } catch (_) {}
    }

    var changed = false;
    
    // Logic fix: Bluesky has multiple rate limits (e.g., for different endpoints).
    // If we just take whatever comes last, it might jump from a low limit (e.g. 3000)
    // to a high limit (e.g. 5000) depending on which API was called.
    // To provide a "worst-case" or "most restrictive" view, we should track the lowest remaining.
    // However, the user wants "decreases as used" and "resets at midnight".
    // Since we can't easily distinguish which limit is which from headers alone without more context,
    // we will at least prevent it from "increasing" within the same reset window.
    
    if (rem != null) {
      if (rateLimitRemaining == null || rem < rateLimitRemaining!) {
        rateLimitRemaining = rem;
        changed = true;
      } else if (rateLimitReset != null && resetDt != null && resetDt.isAfter(rateLimitReset!)) {
        // If the reset time has moved forward significantly, it's likely a new window
        rateLimitRemaining = rem;
        changed = true;
      }
    }
    
    if (limit != null && limit != rateLimitLimit) { rateLimitLimit = limit; changed = true; }
    if (resetDt != null && resetDt != rateLimitReset) { rateLimitReset = resetDt; changed = true; }

    if (changed) {
      rateLimitNotifier.value = {
        'remaining': rateLimitRemaining,
        'limit': rateLimitLimit,
        'reset': rateLimitReset?.toIso8601String(),
      };

      // Persist snapshot (including last_reset) asynchronously
      try {
        _saveRateLimitSnapshot();
      } catch (_) {}

      // Trigger in-app notification callback: simple cooldown to avoid spamming
      try {
        if (rateLimitNotifyEnabled) {
          if (rateLimitRemaining != null && rateLimitRemaining! <= rateLimitNotifyThreshold) {
            final now = DateTime.now();
            if (_lastRateLimitNotifiedAt == null || now.difference(_lastRateLimitNotifiedAt!) > _rateLimitNotifyCooldown) {
              _lastRateLimitNotifiedAt = now;
              // For now we only log; UI can observe `rateLimitNotifier` and show banner/notification.
              debugPrint('Rate limit low: remaining=$rateLimitRemaining limit=$rateLimitLimit reset=$rateLimitReset');
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveAvatarManifest() async {
    if (kIsWeb) return; // not supported on web
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_avatarManifestFile');

      // Prune if too many entries
      await _pruneAvatarManifestIfNeeded(dir.path);

      // Write atomically: write to temp file then rename
      final tmp = File('${dir.path}/$_avatarManifestFile.tmp');
      await tmp.writeAsString(jsonEncode(_avatarManifest), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('Failed to save avatar manifest: $e');
    }
  }

  Future<void> _pruneAvatarManifestIfNeeded(String dirPath) async {
    if (kIsWeb) return;
    try {
      if (_avatarManifest.length <= _maxAvatarManifestEntries) return;
      // Build list of entries with file modified times
      final List<MapEntry<String, String>> entries = _avatarManifest.entries.toList();
      final List<MapEntry<String, int>> withTimes = [];
      for (final e in entries) {
        try {
          final f = File(e.value);
          if (f.existsSync()) {
            final t = f.lastModifiedSync().millisecondsSinceEpoch;
            withTimes.add(MapEntry(e.key, t));
          } else {
            withTimes.add(MapEntry(e.key, 0));
          }
        } catch (_) {
          withTimes.add(MapEntry(e.key, 0));
        }
      }
      // Sort by oldest first
      withTimes.sort((a, b) => a.value.compareTo(b.value));
      final toRemove = withTimes.take(_avatarManifest.length - _maxAvatarManifestEntries).map((e) => e.key).toList();
      for (final k in toRemove) {
        _avatarManifest.remove(k);
      }
    } catch (e) {
      debugPrint('Failed to prune avatar manifest: $e');
    }
  }

  /// Rebuild the manifest by scanning the application documents directory for files
  /// created by the avatar prefetcher (files named `avatar_url_<base64>.jpg`).
  Future<void> rebuildAvatarManifestFromFiles() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      if (!await d.exists()) return;
      final Map<String, String> rebuilt = {};
      await for (final ent in d.list()) {
        if (ent is File) {
          final name = ent.uri.pathSegments.last;
          if (name.startsWith('avatar_url_')) {
            // name: avatar_url_<base64>.jpg
            final rest = name.substring('avatar_url_'.length);
            final dot = rest.indexOf('.');
            final base = dot == -1 ? rest : rest.substring(0, dot);
            try {
              final decoded = utf8.decode(base64Url.decode(base));
              rebuilt[decoded] = ent.path;
            } catch (_) {
              // ignore invalid names
            }
          }
        }
      }
      _avatarManifest
        ..clear()
        ..addAll(rebuilt);
      await _saveAvatarManifest();
      debugPrint('Rebuilt avatar manifest: ${_avatarManifest.length} entries');
    } catch (e) {
      debugPrint('Failed to rebuild avatar manifest: $e');
    }
  }

  String? getLocalAvatarPathForUrl(String url) {
    if (kIsWeb) return null;
    final path = _avatarManifest[url];
    if (path == null) return null;
    try {
      final f = File(path);
      if (f.existsSync()) return path;
    } catch (_) {}
    return null;
  }

  // Prefetch avatars for a list of posts asynchronously (fire-and-forget).
  Future<void> prefetchAvatarsForPosts(List<PostItem> posts, {int concurrency = 4}) async {
    if (kIsWeb) return; // no local avatar caching on web
    if (posts.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();

    final sem = _AsyncSemaphore(concurrency);
    final futures = <Future>[];

    for (final p in posts) {
      final url = p.avatar;
      if (url == null || url.isEmpty) continue;
      if (!url.startsWith('http')) continue;

      // Skip if already have local mapping and file exists
      final existing = getLocalAvatarPathForUrl(url);
      if (existing != null) continue;

      futures.add(Future(() async {
        await sem.acquire();
        try {
          final uri = Uri.parse(url);
          final resp = await http.get(uri).timeout(const Duration(seconds: 10));
          if (resp.statusCode == 200) {
            final bytes = resp.bodyBytes;
            try {
              final decoded = img.decodeImage(bytes);
              final String name = base64Url.encode(utf8.encode(url));
              final file = File('${dir.path}/avatar_url_$name.jpg');
              if (decoded != null) {
                final resized = img.copyResize(decoded, width: 128);
                final jpg = img.encodeJpg(resized, quality: 60);
                await file.writeAsBytes(jpg, flush: true);
              } else {
                await file.writeAsBytes(bytes, flush: true);
              }
              _avatarManifest[url] = file.path;
              await _saveAvatarManifest();
            } catch (e) {
              debugPrint('Failed to process avatar $url: $e');
            }
          }
        } catch (e) {
          debugPrint('Failed to download avatar $url: $e');
        } finally {
          sem.release();
        }
      }));
    }

    await Future.wait(futures);
  }

  Future<bool> refreshSession() async {
    if (_bluesky == null) {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return false;
      try {
        final session = Session.fromJson(jsonDecode(sessionJson));
        return await _manualRefresh(session);
      } catch (_) {
        return false;
      }
    }

    try {
      final response = await _bluesky!.atproto.server.refreshSession();
      final dynamic respData = response.data;

      Session newSession;
      if (respData is Session) {
        newSession = respData;
      } else {
        try {
          final dynamicMap = (respData as dynamic).toJson();
          newSession = Session.fromJson(Map<String, dynamic>.from(dynamicMap));
        } catch (e) {
          debugPrint('Unable to extract Session from refresh response: $e');
          return false;
        }
      }

      await activateSession(newSession);
      await _storage.write(key: _sessionKey, value: jsonEncode(newSession.toJson()));
      await _addAccount(newSession);
      return true;
    } catch (e) {
      debugPrint('Failed to refresh session via client: $e');
      // Try manual refresh as fallback
      try {
        final sessionJson = await _storage.read(key: _sessionKey);
        if (sessionJson == null) return false;
        final session = Session.fromJson(jsonDecode(sessionJson));
        return await _manualRefresh(session);
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _addAccount(Session session) async {
    final accountsJson = await _storage.read(key: _accountsKey);
    List<dynamic> accounts = [];
    if (accountsJson != null) {
      accounts = jsonDecode(accountsJson);
    }

    // If an account for this DID already exists, delete its old avatar file
    final existingIndex = accounts.indexWhere((a) => a['did'] == session.did);
    if (existingIndex != -1) {
      try {
        final existing = accounts[existingIndex];
        final existingAvatar = existing['avatar'] as String?;
        if (existingAvatar != null && existingAvatar.isNotEmpty && existingAvatar != avatar) {
          final f = File(existingAvatar);
          if (f.existsSync()) {
            await f.delete();
            debugPrint('Deleted old avatar file: $existingAvatar');
          }
        }
      } catch (e) {
        debugPrint('Error deleting old avatar file for ${session.did}: $e');
      }
      accounts.removeAt(existingIndex);
    }

    // Add new account info
    accounts.add({
      'handle': session.handle,
      'did': session.did,
      'avatar': avatar, // local path if available
      'avatar_url': avatarUrl, // original remote URL
      'session': session.toJson(),
    });

    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(accountsJson));
  }

  Future<void> switchAccount(String targetDid) async {
    final accounts = await getAccounts();
    final account = accounts.firstWhere((a) => a['did'] == targetDid, orElse: () => throw Exception('アカウントが見つかりません'));
    
    final session = Session.fromJson(account['session']);
    await activateSession(session);
    
    // Update current session key
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<bool> restoreSession() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return false;

      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final session = Session.fromJson(sessionData);

      try {
        await activateSession(session);
        // Ensure the current account is in the accounts list (for migration/consistency)
        await _addAccount(session);
        debugPrint('Session restored. Handle: $handle');
        return true;
      } catch (e) {
        debugPrint('Failed to activate session: $e');
        
        // Check if it's an authentication error
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('unauthorized') || 
            errorStr.contains('expired') || 
            errorStr.contains('invalid token') ||
            errorStr.contains('auth')) {
          
          debugPrint('Authentication error detected, trying manual refresh...');
          final refreshed = await _manualRefresh(session);
          if (refreshed) {
            debugPrint('Manual refresh successful.');
            return true;
          } else {
            debugPrint('Manual refresh failed, logging out.');
            await logout();
            return false;
          }
        } else {
          // Likely a network error. Don't logout, but we can't proceed.
          debugPrint('Non-auth error during session restore. Keeping session but returning false.');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Critical failure in restoreSession: $e');
      // Only logout on data corruption
      if (e is FormatException) {
        await logout();
      }
      return false;
    }
  }

  Future<bool> _manualRefresh(Session oldSession) async {
    try {
      // Create a temporary client to perform the refresh
      final tempClient = Bluesky.fromSession(oldSession);
      final response = await tempClient.atproto.server.refreshSession();
      final dynamic respData = response.data;

      Session newSession;
      if (respData is Session) {
        newSession = respData;
      } else {
        try {
          final dynamicMap = (respData as dynamic).toJson();
          newSession = Session.fromJson(Map<String, dynamic>.from(dynamicMap));
        } catch (e) {
          debugPrint('Unable to extract Session from refresh response: $e');
          return false;
        }
      }

      await activateSession(newSession);
      await _storage.write(key: _sessionKey, value: jsonEncode(newSession.toJson()));
      await _addAccount(newSession);
      return true;
    } catch (e) {
      debugPrint('Manual refresh failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final currentDid = did;
    _bluesky = null;
    handle = null;
    did = null;
    avatar = null;
    await _storage.delete(key: _sessionKey);
    
    if (currentDid != null) {
      final accounts = await getAccounts();
      try {
        final existingIndex = accounts.indexWhere((a) => a['did'] == currentDid);
        if (existingIndex != -1) {
          final existing = accounts[existingIndex];
          final existingAvatar = existing['avatar'] as String?;
          if (existingAvatar != null && existingAvatar.isNotEmpty) {
            try {
              final f = File(existingAvatar);
              if (f.existsSync()) {
                await f.delete();
                debugPrint('Deleted avatar file for logout: $existingAvatar');
              }
            } catch (e) {
              debugPrint('Failed to delete avatar file on logout: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Error while attempting to delete avatar on logout: $e');
      }

      accounts.removeWhere((a) => a['did'] == currentDid);
      await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
    }
  }

  Future<FeedResponse> getTimeline({int limit = 40, String? cursor, bool forceRefresh = false}) async {
    if (_bluesky == null || did == null) {
      throw Exception('Not logged in');
    }
    // Check persistent cache meta for TTL. If expired, clear cache; if within TTL, return cached.
    try {
      if (!kIsWeb) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final key = 'following';
        final last = await _db.getCacheFetched(did!, key);
        if (cursor == null && last != null && !forceRefresh) {
          if ((now - last) < _ttlTimeline.inMilliseconds) {
            final cached = await getCachedTimeline(limit: limit);
            if (cached.isNotEmpty) {
              debugPrint('Returning cached timeline (within TTL)');
              return FeedResponse(posts: cached, cursor: null);
            }
          } else {
            // expired -> clear cache for this feed
            debugPrint('Timeline cache expired, clearing cached entries for $key');
            await _db.clearFeedCache(did!, key);
          }
        }
      }
    } catch (e) {
      debugPrint('TTL check for timeline failed: $e');
    }

    try {
      debugPrint('Fetching timeline...');
      final response = await _bluesky!.feed.getTimeline(limit: limit, cursor: cursor);
      // try to extract rate-limit headers
      try {
        _recordRateLimitFromResponse(response);
      } catch (_) {}
      final feedItems = response.data.feed;
      final nextCursor = response.data.cursor;
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
      
      // Save to cache (only for first page). Keep only full JSON for the latest 'limit' posts,
      // older posts will be stored as text-only and pruned after 7 days.
      if (cursor == null) {
        if (!kIsWeb) {
          if (!kIsWeb) {
            await _db.savePostsWithRetention(did!, 'following', posts, keepFull: limit);
            // Also prune posts older than 7 days for this user
            await _db.prunePostsOlderThan(did!, days: 7);
          }
        }
        // Start avatar prefetch in background (safe on web)
        _maybePrefetchAvatars(posts);
      }
      
      return FeedResponse(posts: posts, cursor: nextCursor);
    } on UnauthorizedException catch (e) {
      throw Exception('Auth Error: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('Failed to fetch timeline: ${e.toString()}');
    } catch (e) {
      throw Exception('Network Error: ${e.toString()}');
    }
  }

  Future<List<PostItem>> getCachedTimeline({int limit = 40}) async {
    if (did == null) return [];
    if (kIsWeb) return [];
    return await _db.getCachedPosts(did!, 'following', limit: limit);
  }

  Future<FeedResponse> getCustomFeed(String feedUri, {int limit = 40, String? cursor, bool forceRefresh = false}) async {
    if (_bluesky == null || did == null) {
      throw Exception('Not logged in');
    }

    // TTL guard: check DB-stored last_fetched; return cached if within TTL, clear if expired
    try {
      debugPrint('Fetching custom feed: $feedUri');
      if (!kIsWeb) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final last = await _db.getCacheFetched(did!, feedUri);
        if (cursor == null && last != null && !forceRefresh) {
          if ((now - last) < _ttlCustomFeed.inMilliseconds) {
            final cached = await getCachedCustomFeed(feedUri, limit: limit);
            if (cached.isNotEmpty) {
              debugPrint('Returning cached custom feed ($feedUri) (within TTL)');
              return FeedResponse(posts: cached, cursor: null);
            }
          } else {
            debugPrint('Custom feed cache expired for $feedUri, clearing');
            await _db.clearFeedCache(did!, feedUri);
          }
        }
      }
      
      final List<dynamic> feedItems;
      final String? nextCursor;

      if (feedUri == 'following') {
        final response = await _bluesky!.feed.getTimeline(limit: limit, cursor: cursor);
        try { _recordRateLimitFromResponse(response); } catch (_) {}
        feedItems = response.data.feed;
        nextCursor = response.data.cursor;
      } else if (feedUri.contains('app.bsky.graph.list')) {
        final response = await _bluesky!.graph.getList(
          list: AtUri.parse(feedUri),
          limit: limit,
          cursor: cursor,
        );
        try { _recordRateLimitFromResponse(response); } catch (_) {}
        feedItems = response.data.items;
        nextCursor = response.data.cursor;
      } else {
        final response = await _bluesky!.feed.getFeed(
          feed: AtUri.parse(feedUri),
          limit: limit,
          cursor: cursor,
        );
        try { _recordRateLimitFromResponse(response); } catch (_) {}
        feedItems = response.data.feed;
        nextCursor = response.data.cursor;
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
      
      // Save to cache (only for first page). Keep only full JSON for the latest 'limit' posts,
      // older posts will be stored as text-only and pruned after 7 days.
      if (cursor == null) {
        if (!kIsWeb) {
          if (!kIsWeb) {
            await _db.savePostsWithRetention(did!, feedUri, posts, keepFull: limit);
            await _db.prunePostsOlderThan(did!, days: 7);
          }
        }
        _maybePrefetchAvatars(posts);
      }
      
      return FeedResponse(posts: posts, cursor: nextCursor);
    } catch (e) {
      throw Exception('Failed to fetch feed: ${e.toString()}');
    }
  }

  Future<List<PostItem>> getCachedCustomFeed(String feedUri, {int limit = 40}) async {
    if (did == null) return [];
    if (kIsWeb) return [];
    if (kIsWeb) return [];
    return await _db.getCachedPosts(did!, feedUri, limit: limit);
  }

  // Internal: after fetching and saving posts, start avatar prefetch asynchronously
  void _maybePrefetchAvatars(List<PostItem> posts) {
    if (posts.isEmpty) return;
    // Fire-and-forget
    unawaited(prefetchAvatarsForPosts(posts));
  }

  Future<List<Map<String, String>>> getSavedFeeds() async {
    if (_bluesky == null) throw Exception('Not logged in');
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
              for (var uri in pinned) {
                savedUris.add(uri.toString());
              }
            }
            if (saved != null) {
              for (var uri in saved) {
                savedUris.add(uri.toString());
              }
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
          {'name': 'Following', 'uri': 'following', 'desc': 'Following Posts'},
        ];
      }

      // Filter only app.bsky.feed.generator URIs for getFeedGenerators
      final feedGenUris = savedUris
          .where((uri) => uri.contains('app.bsky.feed.generator'))
          .map((e) => AtUri.parse(e))
          .toList();
      
      final listUris = savedUris
          .where((uri) => uri.contains('app.bsky.graph.list'))
          .map((e) => AtUri.parse(e))
          .toList();

      debugPrint('Feed Generator URIs: ${feedGenUris.length}');
      debugPrint('List URIs: ${listUris.length}');

      final List<Map<String, String>> result = [];
      result.add({'name': 'Following', 'uri': 'following', 'desc': 'Following Posts'});

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

      if (listUris.isNotEmpty) {
        for (final uri in listUris) {
          try {
            final listResponse = await _bluesky!.graph.getList(
              list: uri,
              limit: 1, // We only need the list metadata
            );
            final list = listResponse.data.list;
            result.add({
              'name': list.name,
              'uri': list.uri.toString(),
              'desc': list.description ?? '',
              'avatar': list.avatar ?? '',
              'indexedAt': list.indexedAt.toIso8601String(),
            });
          } catch (e) {
            debugPrint('Error calling getList for $uri: $e');
          }
        }
      }

      // Fallback for any URIs that couldn't be fetched
      for (var uri in savedUris) {
        if (uri != 'following' && !result.any((element) => element['uri'] == uri)) {
          result.add({
            'name': 'Unknown Item',
            'uri': uri,
            'desc': uri,
            'indexedAt': DateTime.now().toIso8601String(),
          });
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
        {'name': 'Following', 'uri': 'following', 'desc': 'Following Posts', 'indexedAt': DateTime.now().toIso8601String()},
      ];
    }
  }

  Future<Blob> uploadBlob(Uint8List bytes) async {
    if (_bluesky == null) throw Exception('Not logged in');
    final response = await _bluesky!.atproto.repo.uploadBlob(bytes: bytes);
    return response.data.blob;
  }

  Future<void> post(String text, {List<EmbedImagesImage>? images, EmbedVideo? video}) async {
    if (_bluesky == null) throw Exception('Not logged in');

    if (text.trim().isEmpty && images == null && video == null) {
      throw Exception('Post content is empty');
    }

    if (text.length > 300) {
      throw Exception('Post must be within 300 characters');
    }

    try {
      UFeedPostEmbed? embed;
      if (images != null && images.isNotEmpty) {
        embed = UFeedPostEmbed.embedImages(data: EmbedImages(images: images));
      } else if (video != null) {
        embed = UFeedPostEmbed.embedVideo(data: video);
      }

      final response = await _bluesky!.feed.post.create(
        text: text,
        embed: embed,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } on UnauthorizedException catch (e) {
      throw Exception('Auth Error: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('Post failed: ${e.toString()}');
    } catch (e) {
      throw Exception('Network Error: ${e.toString()}');
    }
  }

  Future<void> like(String cid, String uri) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      debugPrint('Attempting like: uri=$uri, cid=$cid');
      final response = await _bluesky!.feed.like.create(
        subject: RepoStrongRef(cid: cid, uri: AtUri.parse(uri)),
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      debugPrint('Like error detail: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Null') && errorStr.contains('subtype') && errorStr.contains('String')) {
        // Parse errorの場合でも、リクエスト自体は成功していることが多いため続行
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
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      debugPrint('Attempting repost: uri=$uri, cid=$cid');
      final response = await _bluesky!.feed.repost.create(
        subject: RepoStrongRef(cid: cid, uri: AtUri.parse(uri)),
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
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

  Future<void> delete(String uri, {String? cid}) async {
    if (_bluesky == null || did == null) throw Exception('Not logged in');
    try {
      final atUri = AtUri.parse(uri);
      final collection = atUri.collection.toString();
      final rkey = atUri.rkey;
      debugPrint('Attempting delete: repo=$did, collection=$collection, rkey=$rkey');
      final response = await _bluesky!.atproto.repo.deleteRecord(
        repo: did!, 
        collection: collection,
        rkey: rkey,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}

      // If it's a post, also delete from local cache to avoid ghost notifications
      if (collection == 'app.bsky.feed.post' && cid != null) {
        if (!kIsWeb) await _db.deletePostFromCache(did!, cid);
      }
    } catch (e) {
      debugPrint('Delete error detail: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Null') && errorStr.contains('subtype') && errorStr.contains('String')) {
        // 削除の場合、Parse errorが出ても実際には消えていることが多い
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

  Future<void> reply(PostItem item, String text, {List<EmbedImagesImage>? images, EmbedVideo? video}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      UFeedPostEmbed? embed;
      if (images != null && images.isNotEmpty) {
        embed = UFeedPostEmbed.embedImages(data: EmbedImages(images: images));
      } else if (video != null) {
        embed = UFeedPostEmbed.embedVideo(data: video);
      }

      final root = item.replyRoot ?? StrongRef(cid: item.id, uri: item.uri);
      final response = await _bluesky!.feed.post.create(
        text: text,
        reply: ReplyRef(
          root: RepoStrongRef(cid: root.cid, uri: AtUri.parse(root.uri)),
          parent: RepoStrongRef(cid: item.id, uri: AtUri.parse(item.uri)),
        ),
        embed: embed,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      debugPrint('Reply error detail: $e');
      if (e is XRPCException) {
        final errorMsg = e.response.data.message;
        throw Exception('返信失敗(${e.response.status.code}): $errorMsg');
      }
      throw Exception('返信失敗: $e');
    }
  }

  Future<void> quote(PostItem item, String text, {List<EmbedImagesImage>? images, EmbedVideo? video}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      UFeedPostEmbed? embed;
      final recordEmbed = EmbedRecord(
        record: RepoStrongRef(cid: item.id, uri: AtUri.parse(item.uri)),
      );

      if (images != null && images.isNotEmpty) {
        embed = UFeedPostEmbed.embedRecordWithMedia(
          data: EmbedRecordWithMedia(
            record: recordEmbed,
            media: UEmbedRecordWithMediaMedia.embedImages(
              data: EmbedImages(images: images),
            ),
          ),
        );
      } else if (video != null) {
        embed = UFeedPostEmbed.embedRecordWithMedia(
          data: EmbedRecordWithMedia(
            record: recordEmbed,
            media: UEmbedRecordWithMediaMedia.embedVideo(
              data: video,
            ),
          ),
        );
      } else {
        embed = UFeedPostEmbed.embedRecord(data: recordEmbed);
      }

      final response = await _bluesky!.feed.post.create(
        text: text,
        embed: embed,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
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
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.feed.getPostThread(uri: AtUri.parse(uri));
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      return response.data.thread;
    } catch (e) {
      debugPrint('GetThread error detail: $e');
      throw Exception('スレッド取得失敗: $e');
    }
  }

  Future<dynamic> getProfile(String actor) async {
    if (_bluesky == null) throw Exception('Not logged in');
    // TTL guard for profile: persist last_fetched in DB under key 'profile:<actor>'
    try {
      final key = 'profile:$actor';
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = (did == null || kIsWeb) ? null : await _db.getCacheFetched(did!, key);
      if (last != null) {
        if ((now - last) < _ttlProfile.inMilliseconds) {
          final cached = _profileCache[actor];
          if (cached != null) {
            debugPrint('Returning cached profile for $actor (within TTL)');
            return cached;
          }
        } else {
          debugPrint('Profile cache expired for $actor, clearing in-memory cache and meta');
          _profileCache.remove(actor);
          if (did != null && !kIsWeb) {
            await _db.clearFeedCache(did!, key);
          }
        }
      }

      final response = await _bluesky!.actor.getProfile(actor: actor);
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      final data = response.data;

      // Cache profile in memory and persist timestamp
      try {
        _profileCache[actor] = data;
        if (did != null && !kIsWeb) {
          await _db.setCacheFetched(did!, key, DateTime.now().millisecondsSinceEpoch);
        }
      } catch (e) {
        debugPrint('Failed to cache profile for $actor: $e');
      }

      return data;
    } catch (e) {
      debugPrint('GetProfile error detail: $e');
      throw Exception('プロフィール取得失敗: $e');
    }
  }

  Future<List<PostItem>> getAuthorFeed(String actor, {int limit = 40}) async {
    if (_bluesky == null) throw Exception('Not logged in');
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
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.feed.searchPosts(
        q: query,
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
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.actor.searchActors(
        term: term,
        limit: limit,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      return response.data.actors;
    } catch (e) {
      debugPrint('SearchActors error detail: $e');
      throw Exception('ユーザー検索失敗: $e');
    }
  }

  Future<void> follow(String did) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.atproto.repo.createRecord(
        repo: _bluesky!.session!.did,
        collection: 'app.bsky.graph.follow',
        record: {
          'subject': did,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      throw Exception('フォロー失敗: $e');
    }
  }

  Future<void> unfollow(String followUri) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final uri = AtUri.parse(followUri);
      final response = await _bluesky!.atproto.repo.deleteRecord(
        repo: uri.hostname,
        collection: uri.collection.toString(),
        rkey: uri.rkey,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      throw Exception('フォロー解除失敗: $e');
    }
  }

  Future<void> mute(String did) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.muteActor(actor: did);
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      throw Exception('ミュート失敗: $e');
    }
  }

  Future<void> unmute(String did) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.unmuteActor(actor: did);
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      throw Exception('ミュート解除失敗: $e');
    }
  }

  Future<void> block(String did) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      await _bluesky!.atproto.repo.createRecord(
        repo: _bluesky!.session!.did,
        collection: 'app.bsky.graph.block',
        record: {
          'subject': did,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('ブロック失敗: $e');
    }
  }

  Future<void> unblock(String blockUri) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final uri = AtUri.parse(blockUri);
      await _bluesky!.atproto.repo.deleteRecord(
        repo: uri.hostname,
        collection: uri.collection.toString(),
        rkey: uri.rkey,
      );
    } catch (e) {
      throw Exception('ブロック解除失敗: $e');
    }
  }

  Future<List<PostItem>> searchAuthorPosts(String query, String author, {int limit = 40}) async {
    return searchPosts('$query from:$author', limit: limit);
  }

  Future<List<dynamic>> getFollows(String actor, {int limit = 50}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.getFollows(actor: actor, limit: limit);
      return response.data.follows;
    } catch (e) {
      throw Exception('フォロー一覧取得失敗: $e');
    }
  }

  Future<List<dynamic>> getFollowers(String actor, {int limit = 50}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.getFollowers(actor: actor, limit: limit);
      return response.data.followers;
    } catch (e) {
      throw Exception('フォロワー一覧取得失敗: $e');
    }
  }

  Future<List<PostItem>> getAuthorFeedWithFilter(String actor, {String? filter, int limit = 40}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      // The SDK expects a specific filter type; apply filtering client-side
      final response = await _bluesky!.feed.getAuthorFeed(
        actor: actor,
        limit: limit,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}

      final allPosts = response.data.feed
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();

      // Save to cache (using a unique key for this author and filter)
      final cacheKey = 'author_feed_${actor}_${filter ?? "all"}';
      if (did != null) {
        await _db.savePostsWithRetention(did!, cacheKey, allPosts, keepFull: limit);
        await _db.prunePostsOlderThan(did!, days: 7);
        _maybePrefetchAvatars(allPosts);
      }

      if (filter == null) return allPosts;

      switch (filter) {
        case 'posts_no_replies':
          return allPosts.where((p) => p.replyParent == null).toList();
        case 'posts_with_replies':
          return allPosts.where((p) => p.replyParent != null).toList();
        case 'posts_with_media':
          return allPosts.where((p) => p.media.isNotEmpty).toList();
        case 'posts_with_video':
          return allPosts.where((p) => p.media.any((m) => m.type == MediaType.video)).toList();
        default:
          return allPosts;
      }
    } catch (e) {
      throw Exception('ユーザー投稿取得失敗: $e');
    }
  }

  Future<List<PostItem>> getCachedAuthorFeed(String actor, {String? filter, int limit = 40}) async {
    if (did == null) return [];
    final cacheKey = 'author_feed_${actor}_${filter ?? "all"}';
    return await _db.getCachedPosts(did!, cacheKey, limit: limit);
  }

  Future<List<PostItem>> getActorLikes(String actor, {int limit = 40}) async {
    if (_bluesky == null || did == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.feed.getActorLikes(actor: actor, limit: limit);
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      final posts = response.data.feed
          .map((f) {
            try {
              return PostItem.fromFeedView(f, handle);
            } catch (e) {
              return null;
            }
          })
          .whereType<PostItem>()
          .toList();

      // Save to cache (keep full for recent items)
      final cacheKey = 'actor_likes_$actor';
      await _db.savePostsWithRetention(did!, cacheKey, posts, keepFull: limit);
      await _db.prunePostsOlderThan(did!, days: 7);
      _maybePrefetchAvatars(posts);

      return posts;
    } catch (e) {
      throw Exception('いいね取得失敗: $e');
    }
  }

  Future<List<PostItem>> getCachedActorLikes(String actor, {int limit = 40}) async {
    if (did == null) return [];
    final cacheKey = 'actor_likes_$actor';
    return await _db.getCachedPosts(did!, cacheKey, limit: limit);
  }

  Future<List<dynamic>> getActorFeeds(String actor, {int limit = 50}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.feed.getActorFeeds(actor: actor, limit: limit);
      return response.data.feeds;
    } catch (e) {
      throw Exception('フィード一覧取得失敗: $e');
    }
  }

  Future<List<dynamic>> getLists(String actor, {int limit = 50}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.getLists(actor: actor, limit: limit);
      return response.data.lists;
    } catch (e) {
      throw Exception('リスト一覧取得失敗: $e');
    }
  }

  // Note: getListsWithMembership is used to see which lists a user is in
  Future<List<dynamic>> getListMemberships(String actor, {int limit = 50}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.graph.getListsWithMembership(actor: actor, limit: limit);
      return response.data.listsWithMembership;
    } catch (e) {
      throw Exception('被リスト一覧取得失敗: $e');
    }
  }

  Future<List<dynamic>> getNotifications({int limit = 40, String? cursor}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.notification.listNotifications(
        limit: limit,
        cursor: cursor,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      return response.data.notifications;
    } catch (e) {
      debugPrint('GetNotifications error: $e');
      throw Exception('通知取得失敗: $e');
    }
  }

  Future<void> updateNotificationsSeen() async {
    if (_bluesky == null) return;
    try {
      final response = await _bluesky!.notification.updateSeen(seenAt: DateTime.now());
      try { _recordRateLimitFromResponse(response); } catch (_) {}
    } catch (e) {
      debugPrint('UpdateNotificationsSeen error: $e');
    }
  }

  Future<List<dynamic>> searchFeeds(String query, {int limit = 20}) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final response = await _bluesky!.unspecced.getPopularFeedGenerators(
        limit: limit,
        query: query.isEmpty ? null : query,
      );
      try { _recordRateLimitFromResponse(response); } catch (_) {}
      return response.data.feeds;
    } catch (e) {
      debugPrint('Error searching feeds: $e');
      return [];
    }
  }

  Future<void> addSavedItem(String uri, String type) async {
    if (_bluesky == null) throw Exception('Not logged in');
    try {
      final prefsResponse = await _bluesky!.actor.getPreferences();
      final prefs = prefsResponse.data.preferences;

      // Convert existing preferences to mutable maps
      final List<Map<String, dynamic>> prefsJson = [];
      for (final p in prefs) {
        try {
          prefsJson.add(Map<String, dynamic>.from(p.toJson()));
        } catch (_) {
          // ignore non-serializable entries
        }
      }

      // Find savedFeedsPrefV2 if present, otherwise find savedFeedsPref V1
      int v2Index = -1;
      int v1Index = -1;
      for (int i = 0; i < prefsJson.length; i++) {
        final json = prefsJson[i];
        final t = json[r'$type'] ?? json['\$type'];
        if (t == 'app.bsky.actor.defs#savedFeedsPrefV2') v2Index = i;
        if (t == 'app.bsky.actor.defs#savedFeedsPref') v1Index = i;
      }

      if (v2Index != -1) {
        // Update V2: items is a list of {id,type,value,pinned}
        final items = List<Map<String, dynamic>>.from(prefsJson[v2Index]['items'] ?? []);
        // Avoid duplicates
        if (items.any((it) => it['value'] == uri)) return;
        items.add({
          'id': 'item-${DateTime.now().millisecondsSinceEpoch}',
          'type': type == 'list' ? 'list' : 'feed',
          'value': uri,
          'pinned': false,
        });
        prefsJson[v2Index]['items'] = items;
      } else if (v1Index != -1) {
        // Update V1 structure: has 'pinned' and 'saved' lists
        final json = prefsJson[v1Index];
        final pinned = List<dynamic>.from(json['pinned'] ?? []);
        final saved = List<dynamic>.from(json['saved'] ?? []);
        if (pinned.contains(uri) || saved.contains(uri)) return;
        saved.add(uri);
        json['saved'] = saved;
        prefsJson[v1Index] = json;
      } else {
        // No existing saved-feeds pref. Create V2 by default.
        prefsJson.add({
          r'$type': 'app.bsky.actor.defs#savedFeedsPrefV2',
          'items': [
            {
              'id': 'item-${DateTime.now().millisecondsSinceEpoch}',
              'type': type == 'list' ? 'list' : 'feed',
              'value': uri,
              'pinned': false,
            }
          ],
        });
      }

      // Call putPreferences with raw JSON using dynamic dispatch to avoid
      // static SDK type mismatches across SDK versions.
      await (_bluesky!.actor as dynamic).putPreferences(preferences: prefsJson);
    } catch (e) {
      debugPrint('Error adding saved item: $e');
      throw Exception('保存失敗: $e');
    }
  }

  Future<void> addSavedFeed(String uri) async {
    await addSavedItem(uri, 'feed');
  }

  // Read Management
  Future<void> updateLastSeen(String feedUri, String postCid, DateTime postAt) async {
    if (did == null) return;
    await _db.updateLastSeen(did!, feedUri, postCid, postAt);
  }

  Future<int> getUnreadCount(String feedUri) async {
    if (did == null) return 0;
    return await _db.getUnreadCount(did!, feedUri);
  }
}

class _AsyncSemaphore {
  int _available;
  final List<Completer<void>> _waiters = [];

  _AsyncSemaphore(this._available);

  Future<void> acquire() {
    if (_available > 0) {
      _available -= 1;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final c = _waiters.removeAt(0);
      if (!c.isCompleted) c.complete();
    } else {
      _available += 1;
    }
  }
}
