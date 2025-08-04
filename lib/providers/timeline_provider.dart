
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/api/bluesky_service.dart';
import 'package:skyscraper/models/post.dart';
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

  Future<void> toggleLike(Post post) async {
    final currentTimeline = state.value!;
    final currentPosts = List<Post>.from(currentTimeline.posts);
    final postIndex = currentPosts.indexWhere((p) => p.uri == post.uri);

    if (postIndex == -1) return; // Post not found

    final isLiked = post.viewer?.like != null;
    final newLikeCount = isLiked ? post.likeCount - 1 : post.likeCount + 1;
    final newViewer = isLiked
        ? post.viewer?.copyWith(like: null)
        : post.viewer?.copyWith(like: 'temp_like_uri'); // Placeholder

    final updatedPost = post.copyWith(
      likeCount: newLikeCount,
      viewer: newViewer,
    );

    currentPosts[postIndex] = updatedPost;

    state = AsyncValue.data(currentTimeline.copyWith(posts: currentPosts));

    try {
      if (isLiked) {
        await ref.read(blueskyServiceProvider).deleteLike(post.viewer!.like!);
      } else {
        final likeRef = await ref.read(blueskyServiceProvider).likePost(post.uri, post.cid);
        // Update with actual like URI
        final finalUpdatedPost = updatedPost.copyWith(
          viewer: updatedPost.viewer?.copyWith(like: likeRef.uri.toString()),
        );
        currentPosts[postIndex] = finalUpdatedPost;
        state = AsyncValue.data(currentTimeline.copyWith(posts: currentPosts));
      }
    } catch (e) {
      // Revert UI on error
      currentPosts[postIndex] = post; // Revert to original post
      state = AsyncValue.data(currentTimeline.copyWith(posts: currentPosts));
      // Optionally, show an error message to the user
      rethrow;
    }
  }
}
