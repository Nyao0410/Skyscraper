
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skyscraper/models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTapPost,
    this.onTapAvatar,
    this.onTapLike,
    this.onTapRepost,
    this.onTapReply,
  });

  final Post post;
  final VoidCallback? onTapPost;
  final VoidCallback? onTapAvatar;
  final VoidCallback? onTapLike;
  final VoidCallback? onTapRepost;
  final VoidCallback? onTapReply;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTapPost,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onTapAvatar,
                    child: CircleAvatar(
                      backgroundImage: post.author.avatar != null
                          ? CachedNetworkImageProvider(post.author.avatar!)
                          : null,
                      child: post.author.avatar == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.displayName ?? post.author.handle,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${post.author.handle}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(post.text),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: onTapReply,
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat),
                    onPressed: onTapRepost,
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: onTapLike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {}, // Not implemented yet
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
