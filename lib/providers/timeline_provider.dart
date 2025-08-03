
import 'dart:async';

import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/api/bluesky_service.dart';

final timelineProvider = AsyncNotifierProvider<TimelineNotifier, List<bsky.FeedView>>(
  () => TimelineNotifier(),
);

class TimelineNotifier extends AsyncNotifier<List<bsky.FeedView>> {
  String? _cursor;

  @override
  Future<List<bsky.FeedView>> build() async {
    final response = await ref.watch(blueskyServiceProvider).getTimeline(limit: 20);
    _cursor = response.cursor;
    return response.feed;
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
    state = AsyncValue.data([...currentState, ...response.feed]);
  }
}
