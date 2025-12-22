import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/post_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  // In-memory fallback for web builds (sqflite is not supported on web).
  final Map<int, Map<String, dynamic>> _inMemoryDrafts = {};
  int _nextDraftId = 1;

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception('Database is not available on web. Use web-safe methods.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bsky_cache.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts (
            cid TEXT,
            user_did TEXT,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_text_only INTEGER DEFAULT 0,
            PRIMARY KEY (cid, user_did)
          )
        ''');
        await db.execute('''
          CREATE TABLE feed_posts (
            feed_uri TEXT,
            post_cid TEXT,
            user_did TEXT,
            indexed_at INTEGER,
            PRIMARY KEY (feed_uri, post_cid, user_did),
            FOREIGN KEY (post_cid, user_did) REFERENCES posts (cid, user_did) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE drafts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_did TEXT,
            text TEXT NOT NULL,
            scheduled_at TEXT, -- ISO8601 string for scheduled posts
            created_at TEXT NOT NULL,
            is_sent INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE last_seen (
            feed_uri TEXT,
            user_did TEXT,
            last_post_cid TEXT,
            last_post_at TEXT,
            PRIMARY KEY (feed_uri, user_did)
          )
        ''');
        await db.execute('''
          CREATE TABLE cache_meta (
            feed_uri TEXT,
            user_did TEXT,
            last_fetched INTEGER,
            PRIMARY KEY (feed_uri, user_did)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS drafts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              text TEXT NOT NULL,
              scheduled_at TEXT, -- ISO8601 string for scheduled posts
              created_at TEXT NOT NULL,
              is_sent INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 3) {
          // Migration to multi-user support
          // For simplicity in this beta, we'll just recreate the tables if they exist
          // or add the user_did column. Recreating is safer for schema changes.
          await db.execute('DROP TABLE IF EXISTS feed_posts');
          await db.execute('DROP TABLE IF EXISTS posts');
          await db.execute('DROP TABLE IF EXISTS drafts');
          
          await db.execute('''
            CREATE TABLE posts (
              cid TEXT,
              user_did TEXT,
              data TEXT NOT NULL,
              created_at TEXT NOT NULL,
              is_text_only INTEGER DEFAULT 0,
              PRIMARY KEY (cid, user_did)
            )
          ''');
          await db.execute('''
            CREATE TABLE feed_posts (
              feed_uri TEXT,
              post_cid TEXT,
              user_did TEXT,
              indexed_at INTEGER,
              PRIMARY KEY (feed_uri, post_cid, user_did),
              FOREIGN KEY (post_cid, user_did) REFERENCES posts (cid, user_did) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE drafts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_did TEXT,
              text TEXT NOT NULL,
              scheduled_at TEXT,
              created_at TEXT NOT NULL,
              is_sent INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS last_seen (
              feed_uri TEXT,
              user_did TEXT,
              last_post_cid TEXT,
              last_post_at TEXT,
              PRIMARY KEY (feed_uri, user_did)
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cache_meta (
              feed_uri TEXT,
              user_did TEXT,
              last_fetched INTEGER,
              PRIMARY KEY (feed_uri, user_did)
            )
          ''');
        }
        if (oldVersion < 6) {
          // Add is_text_only column to posts for reduced-storage of older posts
          try {
            await db.execute('ALTER TABLE posts ADD COLUMN is_text_only INTEGER DEFAULT 0');
          } catch (e) {
            // ignore if column already exists or DB doesn't support ALTER
          }
        }
      },
    );
  }

  // Draft & Scheduled Post Methods
  Future<int> saveDraft(String userDid, String text, {DateTime? scheduledAt}) async {
    if (kIsWeb) {
      final id = _nextDraftId++;
      _inMemoryDrafts[id] = {
        'id': id,
        'user_did': userDid,
        'text': text,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'is_sent': 0,
      };
      return id;
    }
    final db = await database;
    return await db.insert('drafts', {
      'user_did': userDid,
      'text': text,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'is_sent': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getDrafts(String userDid) async {
    if (kIsWeb) {
      final list = _inMemoryDrafts.values.where((d) => d['user_did'] == userDid && (d['is_sent'] == 0 || d['is_sent'] == null)).toList();
      list.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      return list;
    }
    final db = await database;
    return await db.query(
      'drafts', 
      where: 'is_sent = 0 AND user_did = ?', 
      whereArgs: [userDid],
      orderBy: 'created_at DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getScheduledPosts(String userDid) async {
    if (kIsWeb) {
      final list = _inMemoryDrafts.values.where((d) => d['user_did'] == userDid && (d['is_sent'] == 0 || d['is_sent'] == null) && d['scheduled_at'] != null).toList();
      list.sort((a, b) => (a['scheduled_at'] as String).compareTo(b['scheduled_at'] as String));
      return list;
    }
    final db = await database;
    return await db.query(
      'drafts',
      where: 'is_sent = 0 AND scheduled_at IS NOT NULL AND user_did = ?',
      whereArgs: [userDid],
      orderBy: 'scheduled_at ASC',
    );
  }

  Future<void> markAsSent(int id) async {
    if (kIsWeb) {
      final d = _inMemoryDrafts[id];
      if (d != null) d['is_sent'] = 1;
      return;
    }
    final db = await database;
    await db.update('drafts', {'is_sent': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateDraft(int id, String text, {DateTime? scheduledAt}) async {
    if (kIsWeb) {
      final d = _inMemoryDrafts[id];
      if (d != null) {
        d['text'] = text;
        d['scheduled_at'] = scheduledAt?.toIso8601String();
      }
      return;
    }
    final db = await database;
    await db.update(
      'drafts',
      {
        'text': text,
        'scheduled_at': scheduledAt?.toIso8601String(),
        // keep created_at as-is
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDraft(int id) async {
    if (kIsWeb) {
      _inMemoryDrafts.remove(id);
      return;
    }
    final db = await database;
    await db.delete('drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getDraftCount(String userDid) async {
    if (kIsWeb) {
      final count = _inMemoryDrafts.values.where((d) => d['user_did'] == userDid && (d['is_sent'] == 0 || d['is_sent'] == null)).length;
      return count;
    }
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM drafts WHERE is_sent = 0 AND user_did = ?', [userDid]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> savePosts(String userDid, String feedUri, List<PostItem> posts) async {
    final db = await database;
    final batch = db.batch();

    for (final post in posts) {
      // Save post data
      batch.insert(
        'posts',
        {
          'cid': post.id,
          'user_did': userDid,
          'data': jsonEncode(post.toJson()),
          'created_at': post.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save feed relationship
      batch.insert(
        'feed_posts',
        {
          'feed_uri': feedUri,
          'post_cid': post.id,
          'user_did': userDid,
          'indexed_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    // Update cache meta last_fetched
    try {
      await db.insert(
        'cache_meta',
        {
          'feed_uri': feedUri,
          'user_did': userDid,
          'last_fetched': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // ignore cache meta failures
    }
  }

  /// Save posts but keep only full JSON for the first [keepFull] items.
  /// Older items will be stored as reduced JSON (text-only) and marked with is_text_only=1.
  Future<void> savePostsWithRetention(String userDid, String feedUri, List<PostItem> posts, {int keepFull = 40}) async {
    final db = await database;
    final batch = db.batch();

    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];
      final bool full = i < keepFull;
      final Map<String, dynamic> dataMap = full
          ? post.toJson()
          : {
              'id': post.id,
              'uri': post.uri,
              'author': post.author,
              'handle': post.handle,
              'text': post.text,
              'createdAt': post.createdAt.toIso8601String(),
            };

      batch.insert(
        'posts',
        {
          'cid': post.id,
          'user_did': userDid,
          'data': jsonEncode(dataMap),
          'created_at': post.createdAt.toIso8601String(),
          'is_text_only': full ? 0 : 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      batch.insert(
        'feed_posts',
        {
          'feed_uri': feedUri,
          'post_cid': post.id,
          'user_did': userDid,
          'indexed_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    // Update cache meta last_fetched
    try {
      await db.insert(
        'cache_meta',
        {
          'feed_uri': feedUri,
          'user_did': userDid,
          'last_fetched': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // ignore
    }
  }

  /// Remove posts older than [days] for the given user. Cleans up feed_posts references too.
  Future<void> prunePostsOlderThan(String userDid, {int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    final List<Map<String, dynamic>> rows = await db.rawQuery('SELECT cid FROM posts WHERE user_did = ? AND created_at < ?', [userDid, cutoff]);
    if (rows.isEmpty) return;

    final cids = rows.map((r) => r['cid'] as String).toList();

    // Delete from feed_posts
    final batch = db.batch();
    for (final cid in cids) {
      batch.delete('feed_posts', where: 'post_cid = ? AND user_did = ?', whereArgs: [cid, userDid]);
    }
    // Delete posts
    for (final cid in cids) {
      batch.delete('posts', where: 'cid = ? AND user_did = ?', whereArgs: [cid, userDid]);
    }

    await batch.commit(noResult: true);
  }

  Future<int?> getCacheFetched(String userDid, String feedUri) async {
    final db = await database;
    final rows = await db.query(
      'cache_meta',
      where: 'feed_uri = ? AND user_did = ?',
      whereArgs: [feedUri, userDid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['last_fetched'] as int?;
  }

  Future<void> setCacheFetched(String userDid, String feedUri, int epochMillis) async {
    final db = await database;
    await db.insert(
      'cache_meta',
      {
        'feed_uri': feedUri,
        'user_did': userDid,
        'last_fetched': epochMillis,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearFeedCache(String userDid, String feedUri) async {
    if (kIsWeb) return;
    final db = await database;
    // Delete feed_posts entries for this feed and user
    await db.delete('feed_posts', where: 'feed_uri = ? AND user_did = ?', whereArgs: [feedUri, userDid]);

    // Delete orphan posts (posts that are not referenced by any feed_posts for this user)
    await db.delete(
      'posts',
      where: 'user_did = ? AND cid NOT IN (SELECT post_cid FROM feed_posts WHERE user_did = ?)',
      whereArgs: [userDid, userDid],
    );

    // Remove cache_meta entry
    await db.delete('cache_meta', where: 'feed_uri = ? AND user_did = ?', whereArgs: [feedUri, userDid]);
  }

  Future<void> clearFeedCacheIfExpired(String userDid, String feedUri, int ttlMillis) async {
    if (kIsWeb) return;
    final last = await getCacheFetched(userDid, feedUri);
    if (last == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if ((now - last) >= ttlMillis) {
      await clearFeedCache(userDid, feedUri);
    }
  }

  Future<List<PostItem>> getCachedPosts(String userDid, String feedUri, {int limit = 40}) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.data FROM posts p
      JOIN feed_posts fp ON p.cid = fp.post_cid AND p.user_did = fp.user_did
      WHERE fp.feed_uri = ? AND fp.user_did = ?
      ORDER BY p.created_at DESC
      LIMIT ?
    ''', [feedUri, userDid, limit]);

    return maps.map((m) {
      final data = jsonDecode(m['data'] as String) as Map<String, dynamic>;
      return PostItem.fromJson(data);
    }).toList();
  }

  Future<void> clearCache() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('feed_posts');
    await db.delete('posts');
  }

  Future<void> deletePostFromCache(String userDid, String cid) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('posts', where: 'cid = ? AND user_did = ?', whereArgs: [cid, userDid]);
  }

  // Read Management Methods
  Future<void> updateLastSeen(String userDid, String feedUri, String postCid, DateTime postAt) async {
    if (kIsWeb) return;
    final db = await database;
    // Ensure the last_seen table exists (handles older DBs that lack the table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_seen (
        feed_uri TEXT,
        user_did TEXT,
        last_post_cid TEXT,
        last_post_at TEXT,
        PRIMARY KEY (feed_uri, user_did)
      )
    ''');

    await db.insert(
      'last_seen',
      {
        'feed_uri': feedUri,
        'user_did': userDid,
        'last_post_cid': postCid,
        'last_post_at': postAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getUnreadCount(String userDid, String feedUri) async {
    if (kIsWeb) return 0;
    final db = await database;
    // Ensure the last_seen table exists (handles older DBs that lack the table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_seen (
        feed_uri TEXT,
        user_did TEXT,
        last_post_cid TEXT,
        last_post_at TEXT,
        PRIMARY KEY (feed_uri, user_did)
      )
    ''');

    // Get last seen timestamp
    final List<Map<String, dynamic>> lastSeen = await db.query(
      'last_seen',
      where: 'feed_uri = ? AND user_did = ?',
      whereArgs: [feedUri, userDid],
    );

    if (lastSeen.isEmpty) {
      // If never seen, count all cached posts for this feed
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM feed_posts WHERE feed_uri = ? AND user_did = ?',
        [feedUri, userDid],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final lastAt = lastSeen.first['last_post_at'] as String;

    // Count posts newer than lastAt
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM posts p
      JOIN feed_posts fp ON p.cid = fp.post_cid AND p.user_did = fp.user_did
      WHERE fp.feed_uri = ? AND fp.user_did = ? AND p.created_at > ?
    ''', [feedUri, userDid, lastAt]);

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
