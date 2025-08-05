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
    required this.isLiked,
    required this.isReposted,
    required this.createdAt,
    this.likeUri,
    this.repostUri,
  });

  /// JSONからPostインスタンスを生成するファクトリコンストラクタ。
  factory Post.fromJson(Map<String, dynamic> json) {
    // ネストした`record`オブジェクトから`text`を抽出
    final record = json['record'] as Map<String, dynamic>;
    // 'viewer'キーの中に'like'があるかどうかで、いいね状態を判断
    final viewer = json['viewer'] as Map<String, dynamic>;
    final likeUri = viewer['like'] as String?;
    final repostUri = viewer['repost'] as String?;

    return Post(
      uri: json['uri'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      text: record['text'] as String,
      likeCount: json['likeCount'] as int,
      repostCount: json['repostCount'] as int,
      createdAt: DateTime.parse(json['indexedAt'] as String),
      isLiked: likeUri != null,
      likeUri: likeUri,
      isReposted: repostUri != null,
      repostUri: repostUri,
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

  /// ユーザーがいいねしたかどうか。
  final bool isLiked;

  /// いいねのURI。いいねしていない場合はnull。
  final String? likeUri;

  /// ユーザーがリポストしたかどうか。
  final bool isReposted;

  /// リポストのURI。リポストしていない場合はnull。
  final String? repostUri;

  /// 状態を更新した新しいインスタンスを返すためのcopyWithメソッド。
  Post copyWith({
    int? likeCount,
    bool? isLiked,
    String? likeUri,
    int? repostCount,
    bool? isReposted,
    String? repostUri,
  }) {
    return Post(
      uri: uri,
      text: text,
      author: author,
      likeCount: likeCount ?? this.likeCount,
      repostCount: repostCount ?? this.repostCount,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      likeUri: likeUri, // likeUriはnull許容なのでそのまま代入
      isReposted: isReposted ?? this.isReposted,
      repostUri: repostUri, // repostUriはnull許容なのでそのまま代入
    );
  }
}
