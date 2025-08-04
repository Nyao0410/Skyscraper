
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required Actor author,
    required String text,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  factory Post.fromFeedView(bsky.FeedView feedView) {
    return Post(
      author: Actor.fromActorBasic(feedView.post.author),
      text: feedView.post.record.text,
      createdAt: feedView.post.record.createdAt,
    );
  }
}

@freezed
class Actor with _$Actor {
  const factory Actor({
    required String did,
    required String handle,
    String? displayName,
    String? avatar,
  }) = _Actor;

  factory Actor.fromJson(Map<String, dynamic> json) => _$ActorFromJson(json);

  factory Actor.fromActorBasic(bsky.ActorBasic actor) {
    return Actor(
      did: actor.did,
      handle: actor.handle,
      displayName: actor.displayName,
      avatar: actor.avatar,
    );
  }
}
