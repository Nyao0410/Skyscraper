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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts (
            cid TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feed_posts (
            feed_uri TEXT,
            post_cid TEXT,
            indexed_at INTEGER,
            PRIMARY KEY (feed_uri, post_cid),
            FOREIGN KEY (post_cid) REFERENCES posts (cid) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE drafts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
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
      },
    );
  }

  // Draft & Scheduled Post Methods
  Future<int> saveDraft(String text, {DateTime? scheduledAt}) async {
    final db = await database;
    return await db.insert('drafts', {
      'text': text,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'is_sent': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final db = await database;
    return await db.query('drafts', where: 'is_sent = 0', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getScheduledPosts() async {
    final db = await database;
    return await db.query(
      'drafts',
      where: 'is_sent = 0 AND scheduled_at IS NOT NULL',
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

  Future<int> getDraftCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM drafts WHERE is_sent = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> savePosts(String feedUri, List<PostItem> posts) async {
    final db = await database;
    final batch = db.batch();

    for (final post in posts) {
      // Save post data
      batch.insert(
        'posts',
        {
          'cid': post.id,
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
          'indexed_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<PostItem>> getCachedPosts(String feedUri, {int limit = 40}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.data FROM posts p
      JOIN feed_posts fp ON p.cid = fp.post_cid
      WHERE fp.feed_uri = ?
      ORDER BY p.created_at DESC
      LIMIT ?
    ''', [feedUri, limit]);

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
