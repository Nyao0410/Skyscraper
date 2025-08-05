import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/fakes/fake_timeline_repository.dart';

part 'timeline_repository.g.dart';

/// Abstract class for timeline repository.
// ignore: one_member_abstracts
abstract class ITimelineRepository {
  /// Fetches a list of posts for the timeline.
  Future<List<Post>> fetchTimeline({String? cursor});

  /// Likes a post with the given URI.
  Future<void> likePost(String uri);

  /// Unlikes a post with the given URI.
  Future<void> unlikePost(String uri);

  /// Reposts a post with the given URI.
  Future<void> repostPost(String uri);

  /// Unreposts a post with the given URI.
  Future<void> unrepostPost(String uri);
}

/// Provides the timeline repository instance.
@Riverpod(keepAlive: true)
ITimelineRepository timelineRepository(Ref ref) {
  return FakeTimelineRepository();
}
