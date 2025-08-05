import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/timeline_repository.dart';

part 'timeline_provider.g.dart';

/// Provides a list of posts for the timeline.
///
/// This asynchronous provider fetches the timeline data from the
/// [timelineRepositoryProvider].
@riverpod
Future<List<Post>> timeline(Ref ref) {
  // Calls the fetchTimeline method of the timelineRepository.
  return ref.watch(timelineRepositoryProvider).fetchTimeline();
}
