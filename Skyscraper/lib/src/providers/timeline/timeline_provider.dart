import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/timeline_repository.dart';

part 'timeline_provider.g.dart';

/// A Riverpod notifier for managing the timeline state.
@riverpod
class Timeline extends _$Timeline {
  /// buildメソッドで、Providerの初期状態を定義する
  @override
  Future<List<Post>> build() async {
    // 最初にタイムラインのデータを取得する
    return ref.watch(timelineRepositoryProvider).fetchTimeline();
  }

  /// 投稿に「いいね」する（Optimistic UI）
  Future<void> toggleLike(String postUri) async {
    final timelineRepository = ref.read(timelineRepositoryProvider);
    
    // 1. 現在の状態を楽観的に（optimistically）更新する
    final previousState = await future;
    final targetPost = previousState.firstWhere((p) => p.uri == postUri);
    final newLikedState = !targetPost.isLiked;

    // UIを即時反映させる
    state = AsyncValue.data(
      previousState.map((post) {
        if (post.uri == postUri) {
          return post.copyWith(
            isLiked: newLikedState,
            likeCount: newLikedState
                ? post.likeCount + 1
                : post.likeCount - 1,
          );
        }
        return post;
      }).toList(),
    );

    // 2. 実際のAPIコールを実行する
    try {
      if (newLikedState) {
        await timelineRepository.likePost(postUri);
      } else {
        // unlikeにはlikeUriが必要だが、Fakeなのでここでは省略
        await timelineRepository.unlikePost(postUri);
      }
    } catch (e) {
      // 3. エラーが発生した場合、UIを元の状態に戻す
      state = AsyncValue.data(previousState);
      // TODO(developer): エラーハンドリングを実装する
    }
  }

  /// 投稿を「リポスト」する（Optimistic UI）
  Future<void> toggleRepost(String postUri) async {
    final timelineRepository = ref.read(timelineRepositoryProvider);
    final previousState = await future;
    final targetPost = previousState.firstWhere((p) => p.uri == postUri);
    final newRepostedState = !targetPost.isReposted;

    // UIを即時反映
    state = AsyncValue.data(
      previousState.map((post) {
        if (post.uri == postUri) {
          return post.copyWith(
            isReposted: newRepostedState,
            repostCount: newRepostedState
                ? post.repostCount + 1
                : post.repostCount - 1,
          );
        }
        return post;
      }).toList(),
    );

    // APIコール
    try {
      if (newRepostedState) {
        await timelineRepository.repostPost(postUri);
      } else {
        await timelineRepository.unrepostPost(postUri);
      }
    } catch (e) {
      // 3. エラーが発生した場合、UIを元の状態に戻す
      state = AsyncValue.data(previousState);
      // TODO(developer): エラーハンドリングを実装する
    }
  }
}
