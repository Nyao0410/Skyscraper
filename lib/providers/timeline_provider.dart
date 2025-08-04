
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/api/bluesky_service.dart';
import 'package:skyscraper/models/post.dart';

final timelineProvider = AsyncNotifierProvider<TimelineNotifier, List<Post>>(
  () => TimelineNotifier(),
);

class TimelineNotifier extends AsyncNotifier<List<Post>> {
  String? _cursor;

  @override
  Future<List<Post>> build() async {
    final response = await ref.watch(blueskyServiceProvider).getTimeline(limit: 20);
    _cursor = response.cursor;
    return response.feed.map((e) => Post.fromFeedView(e)).toList();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || _cursor == null) {
      return;
    }

    state = const AsyncValue.loading();

    final response = await ref.watch(blueskyServiceProvider).getTimeline(
          cursor: _cursor,
          limit: 20,
        );

    _cursor = response.cursor;
    final currentState = state.value ?? [];
    final newPosts = response.feed.map((e) => Post.fromFeedView(e)).toList();
    state = AsyncValue.data([...currentState, ...newPosts]);
  }
}
