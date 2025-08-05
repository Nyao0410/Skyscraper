import 'package:flutter/material.dart';
import 'package:skyscraper/src/constants/sizes.dart';
import 'package:skyscraper/src/models/post.dart';

/// 投稿一つ分を表示するカード型ウィジェット。
class PostCard extends StatelessWidget {
  /// PostCardのコンストラクタ。
  const PostCard({required this.post, super.key});

  /// 表示対象の投稿データ。
  final Post post;

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 投稿ヘッダー (アバター、名前、ハンドル)
            Row(
              children: [
                // アバター
                CircleAvatar(
                  radius: 24,
                  backgroundImage: author.avatar != null
                      ? NetworkImage(author.avatar!)
                      : null,
                  child: author.avatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: p12),
                // 名前とハンドル
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.displayName ?? author.handle,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ' @${author.handle}',
                        style: textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: p8),

            // 投稿本文
            Text(post.text, style: textTheme.bodyLarge),
            const SizedBox(height: p12),

            // アクションボタン (リプライ、リポスト、いいね、その他)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: 0, // replyCountはPostモデルにまだないため0
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: Icons.repeat,
                  count: post.repostCount,
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: Icons.favorite_border,
                  count: post.likeCount,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  iconSize: iconSizeM,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// PostCard内部で使用するアクションボタンウィジェット。
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onPressed,
  });

  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: iconSizeM,
          onPressed: onPressed,
        ),
        Text(
          count.toString(),
          style: textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
