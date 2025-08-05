import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/src/constants/sizes.dart'; // importを追加
import 'package:skyscraper/src/providers/timeline/timeline_provider.dart';
import 'package:skyscraper/src/widgets/common/error_display.dart';
import 'package:skyscraper/src/widgets/common/loading_indicator.dart';
import 'package:skyscraper/src/widgets/post_card.dart'; // importを追加

/// The home screen of the application.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: timelineState.when(
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorDisplay(message: error.toString()),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No posts found.'));
          }
          // ListView.builderを、PostCardを返すように変更
          return ListView.separated(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // ListTileの代わりにPostCardを返す
              return PostCard(
                post: post,
                onLikePressed: () {
                  ref.read(timelineProvider.notifier).toggleLike(post.uri);
                },
                onRepostPressed: () {
                  ref.read(timelineProvider.notifier).toggleRepost(post.uri);
                },
              );
            },
            // 各カードの間にスペースを設ける
            separatorBuilder: (context, index) => const Divider(height: p8),
          );
        },
      ),
    );
  }
}
