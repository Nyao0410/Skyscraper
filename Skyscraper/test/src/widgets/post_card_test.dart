import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyscraper/src/models/author.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/widgets/post_card.dart';

void main() {
  // Helper function to render PostCard in a testable state.
  Future<void> pumpPostCard(WidgetTester tester, Post post) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: post,
            onLikePressed: () {},
            onRepostPressed: () {},
          ),
        ),
      ),
    );
    // Ensure all animations and asynchronous operations are complete.
    await tester.pumpAndSettle();
  }

  group('PostCard Widget Test', () {
    testWidgets('全てのデータが正常に表示されること', (WidgetTester tester) async {
      // 1. Setup: Create mock data for testing.
      final mockPost = Post(
        uri: 'uri_1',
        text: 'This is a test post.',
        author: const Author(
          handle: 'test.bsky.social',
          displayName: 'Test User',
          avatar: null, // Set avatar to null to avoid network requests.
        ),
        likeCount: 10,
        repostCount: 5,
        createdAt: DateTime.utc(2023, 1, 1),
        isLiked: false,
        isReposted: false,
      );

      // 2. Action: Render the PostCard widget.
      await pumpPostCard(tester, mockPost);

      // 3. Verification: Check if all elements are displayed correctly.
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text(' @test.bsky.social'), findsOneWidget);
      expect(find.text('This is a test post.'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Like count.
      expect(find.text('5'), findsOneWidget); // Repost count.
      expect(find.byType(CircleAvatar), findsOneWidget);
      // Verify that the person icon is displayed since avatar is null.
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets(
        'オプショナルなデータ（displayName）がnullの場合、ハンドルが表示されること',
        (WidgetTester tester) async {
      // 1. Setup: Create mock data with null displayName.
      final mockPost = Post(
        uri: 'uri_2',
        text: 'Another post without a display name.',
        author: const Author(
          handle: 'minimal.bsky.social',
          // displayName is null.
          avatar: null, // Set avatar to null to avoid network requests.
        ),
        likeCount: 0,
        repostCount: 0,
        createdAt: DateTime.utc(2023, 1, 1),
        isLiked: false,
        isReposted: false,
      );

      // 2. Action: Render the widget.
      await pumpPostCard(tester, mockPost);

      // 3. Verification:
      // Handle should be displayed since displayName is null.
      expect(find.text('minimal.bsky.social'), findsOneWidget);
      expect(find.text(' @minimal.bsky.social'), findsOneWidget);
      // Verify that the person icon is displayed since avatar is null.
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}