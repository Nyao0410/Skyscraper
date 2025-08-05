import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/fakes/fake_timeline_repository.dart';
part 'timeline_repository.g.dart';

abstract class ITimelineRepository {
  Future<List<Post>> fetchTimeline({String? cursor});
}

@Riverpod(keepAlive: true)
ITimelineRepository timelineRepository(Ref ref) {
  return FakeTimelineRepository();
}