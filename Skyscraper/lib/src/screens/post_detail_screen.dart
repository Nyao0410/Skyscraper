import 'package:flutter/material.dart';

/// A screen to display the details of a single post.
class PostDetailScreen extends StatelessWidget {
  /// Creates a [PostDetailScreen] widget.
  const PostDetailScreen({required this.postId, super.key});

  /// The ID of the post to display.
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail')),
      body: Center(
        child: Text('Post ID: $postId'),
      ),
    );
  }
}
