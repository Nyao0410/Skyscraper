import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/providers/timeline/timeline_provider.dart';
import 'package:skyscraper/src/repositories/timeline_repository.dart';

part 'create_post_controller.g.dart';

/// A Riverpod controller for managing the post creation process.
@riverpod
class CreatePostController extends _$CreatePostController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Submits a new post with the given text.
  ///
  /// Returns `true` if the post was submitted successfully, `false` otherwise.
  Future<bool> submitPost(String text) async {
    state = const AsyncValue.loading();
    try {
      // Call the repository's createPost method.
      await ref.read(timelineRepositoryProvider).createPost(text: text);
      state = const AsyncValue.data(null);
      
      // Invalidate the timelineProvider to trigger a refresh.
      ref.invalidate(timelineProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
