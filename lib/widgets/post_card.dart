
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final bsky.Post post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (post.author.avatar != null)
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(post.author.avatar!),
                  ),
                const SizedBox(width: 8),
                Text(
                  post.author.displayName ?? post.author.handle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.record.text),
          ],
        ),
      ),
    );
  }
}
