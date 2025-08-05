import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/src/providers/timeline/timeline_provider.dart';
import 'package:skyscraper/src/widgets/common/error_display.dart';
import 'package:skyscraper/src/widgets/common/loading_indicator.dart';

/// The home screen of the application.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // タイムラインの状態を監視する
    final timelineState = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: timelineState.when(
        // ローディング中
        loading: () => const LoadingIndicator(),
        // エラー発生時
        error: (error, stackTrace) => ErrorDisplay(message: error.toString()),
        // データ取得成功時
        data: (posts) {
          // 投稿が0件の場合の表示
          if (posts.isEmpty) {
            return const Center(child: Text('No posts found.'));
          }
          // 投稿リストを表示
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                title: Text(post.author.displayName ?? post.author.handle),
                subtitle: Text(post.text),
              );
            },
          );
        },
      ),
    );
  }
}
