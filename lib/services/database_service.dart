import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/post_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bsky_cache.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts (
            cid TEXT,
            user_did TEXT,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL,
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
        }
      },
    );
  }

  // Draft & Scheduled Post Methods
  Future<int> saveDraft(String userDid, String text, {DateTime? scheduledAt}) async {
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
    final db = await database;
    return await db.query(
      'drafts', 
      where: 'is_sent = 0 AND user_did = ?', 
      whereArgs: [userDid],
      orderBy: 'created_at DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getScheduledPosts(String userDid) async {
    final db = await database;
    return await db.query(
      'drafts',
      where: 'is_sent = 0 AND scheduled_at IS NOT NULL AND user_did = ?',
      whereArgs: [userDid],
      orderBy: 'scheduled_at ASC',
    );
  }

  Future<void> markAsSent(int id) async {
    final db = await database;
    await db.update('drafts', {'is_sent': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDraft(int id) async {
    final db = await database;
    await db.delete('drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getDraftCount(String userDid) async {
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
  }

  Future<List<PostItem>> getCachedPosts(String userDid, String feedUri, {int limit = 40}) async {
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
    final db = await database;
    await db.delete('feed_posts');
    await db.delete('posts');
  }
}
