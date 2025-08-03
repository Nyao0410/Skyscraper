
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyscraper/widgets/post_card.dart';
import 'package:bluesky/bluesky.dart' as bsky;

void main() {
  testWidgets('PostCard displays post content', (WidgetTester tester) async {
    final post = bsky.Post(
      uri: 'at://did:plc:test/app.bsky.feed.post/1',
      cid: 'bafyreibm25pknp2d36z6dyi2w5rd7j5t36j6j6j6j6j6j6j6j6j',
      author: bsky.Actor(
        did: 'did:plc:test',
        handle: 'test.bsky.social',
        displayName: 'Test User',
        avatar: 'https://example.com/avatar.png',
      ),
      record: bsky.Record(text: 'This is a test post', createdAt: DateTime.now()),
      replyCount: 0,
      repostCount: 0,
      likeCount: 0,
      indexedAt: DateTime.now(),
      viewer: bsky.Viewer(reposted: false, liked: false),
    );

    await tester.pumpWidget(MaterialApp(home: PostCard(post: post)));

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('This is a test post'), findsOneWidget);
  });
}
