import 'package:skyscraper/src/models/author.dart';

/// 投稿を表す、手動で実装されたプレーンなDartクラス。
class Post {
  /// Creates a [Post] instance.
  const Post({
    required this.uri,
    required this.text,
    required this.author,
    required this.likeCount,
    required this.repostCount,
    required this.createdAt,
  });

  /// JSONからPostインスタンスを生成するファクトリコンストラクタ。
  factory Post.fromJson(Map<String, dynamic> json) {
    // ネストした`record`オブジェクトから`text`を抽出
    final record = json['record'] as Map<String, dynamic>;

    return Post(
      uri: json['uri'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      text: record['text'] as String,
      likeCount: json['likeCount'] as int,
      repostCount: json['repostCount'] as int,
      createdAt: DateTime.parse(json['indexedAt'] as String),
    );
  }

  /// 投稿のURI。
  final String uri;

  /// 投稿本文。
  final String text;

  /// 投稿者。
  final Author author;

  /// 「いいね」の数。
  final int likeCount;

  /// 「リポスト」の数。
  final int repostCount;

  /// 投稿日時。
  final DateTime createdAt;
}
