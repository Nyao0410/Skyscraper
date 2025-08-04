
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyscraper/widgets/post_card.dart';
import '../mocks/mock_data.dart';

void main() {
  testWidgets('PostCard displays user info and post text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: mockPost),
        ),
      ),
    );

    // Verify that the user's display name, handle, and post text are displayed.
    expect(find.text(mockPost.author.displayName!),
        findsOneWidget);
    expect(find.text('@${mockPost.author.handle}'), findsOneWidget);
    expect(find.text(mockPost.text), findsOneWidget);
  });
}
