import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skyscraper/src/constants/sizes.dart';
import 'package:skyscraper/src/providers/post/create_post_controller.dart';

/// 新規投稿を作成する画面。
/// 新規投稿を作成する画面。
class CreatePostScreen extends ConsumerStatefulWidget {
  /// 新規投稿画面のコンストラクタ。
  /// 新規投稿画面のコンストラクタ。
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.listenでProviderの状態変化を監視し、副作用（画面遷移やSnackBar表示）を実行
    ref.listen<AsyncValue<void>>(createPostControllerProvider, (_, state) {
      // エラーがなく、かつデータも存在する場合（＝成功時）のみ画面を閉じる
      // これにより、非同期処理の完了後に安全に画面遷移を実行できる
      if (!state.isLoading && !state.hasError) {
        context.pop();
      }
      // エラー時のSnackBar表示などは、必要に応じてここに追加できる
    });

    final state = ref.watch(createPostControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            // ボタンが押されたら、単純にControllerのメソッドを呼ぶだけにする
            // ここでの`await`や`mounted`チェックは不要になる
            onPressed: isLoading
                ? null
                : () => ref
                    .read(createPostControllerProvider.notifier)
                    .submitPost(_textController.text),
            child: const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(p8),
        child: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: "What's up?",
            border: InputBorder.none,
          ),
          maxLines: null,
          autofocus: true,
        ),
      ),
    );
  }
}
