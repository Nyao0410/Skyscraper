import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:skyscraper/src/models/author.dart';
part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String uri,
    required String text,
    required Author author,
    @JsonKey(name: 'likeCount') required int likeCount,
    @JsonKey(name: 'repostCount') required int repostCount,
    @JsonKey(name: 'indexedAt') required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$Post.fromJson(json);
}
