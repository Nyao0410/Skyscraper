
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:skyscraper/widgets/post_card.dart';
import '../mocks/mock_data.dart';

// Mock class for callbacks
class MockCallbacks extends Mock {
  void onTapPost();
  void onTapAvatar();
  void onTapLike();
  void onTapRepost();
  void onTapReply();
}

void main() {
  late MockCallbacks mockCallbacks;

  setUp(() {
    mockCallbacks = MockCallbacks();
  });

  testWidgets('PostCard displays user info and post text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: mockPost),
        ),
      ),
    );

    expect(find.text(mockPost.author.displayName!), findsOneWidget);
    expect(find.text('@${mockPost.author.handle}'), findsOneWidget);
    expect(find.text(mockPost.text), findsOneWidget);
  });

  testWidgets('onTapPost callback is called when post is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: mockPost,
            onTapPost: mockCallbacks.onTapPost,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PostCard));
    verify(mockCallbacks.onTapPost()).called(1);
  });

  testWidgets('onTapAvatar callback is called when avatar is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: mockPost,
            onTapAvatar: mockCallbacks.onTapAvatar,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CircleAvatar));
    verify(mockCallbacks.onTapAvatar()).called(1);
  });

  testWidgets('onTapLike callback is called when like button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: mockPost,
            onTapLike: mockCallbacks.onTapLike,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_border));
    verify(mockCallbacks.onTapLike()).called(1);
  });

  testWidgets('onTapRepost callback is called when repost button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: mockPost,
            onTapRepost: mockCallbacks.onTapRepost,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat));
    verify(mockCallbacks.onTapRepost()).called(1);
  });

  testWidgets('onTapReply callback is called when reply button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: mockPost,
            onTapReply: mockCallbacks.onTapReply,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    verify(mockCallbacks.onTapReply()).called(1);
  });
}
