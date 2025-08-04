
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/api/bluesky_service.dart';
import 'package:skyscraper/models/timeline.dart';

final timelineProvider = AsyncNotifierProvider<TimelineNotifier, Timeline>(
  () => TimelineNotifier(),
);

class TimelineNotifier extends AsyncNotifier<Timeline> {
  @override
  Future<Timeline> build() async {
    return ref.watch(blueskyServiceProvider).findTimeline(limit: 20);
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.value == null || state.value!.cursor == null) {
      return;
    }

    final currentState = state.value!;
    state = const AsyncValue.loading();

    final response = await ref.watch(blueskyServiceProvider).findTimeline(
          cursor: currentState.cursor,
          limit: 20,
        );

    state = AsyncValue.data(
      currentState.copyWith(
        posts: [...currentState.posts, ...response.posts],
        cursor: response.cursor,
      ),
    );
  }

  Future<void> pullToRefresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.watch(blueskyServiceProvider).findTimeline(limit: 20),
    );
  }
}
