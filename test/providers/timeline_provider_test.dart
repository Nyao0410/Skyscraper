
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:skyscraper/api/bluesky_service.dart';
import 'package:skyscraper/models/post.dart';
import 'package:skyscraper/models/timeline.dart';
import 'package:skyscraper/providers/timeline_provider.dart';

import 'timeline_provider_test.mocks.dart';

@GenerateMocks([BlueskyService])
void main() {
  late MockBlueskyService mockBlueskyService;
  late ProviderContainer container;

  setUp(() {
    mockBlueskyService = MockBlueskyService();
    container = ProviderContainer(
      overrides: [
        blueskyServiceProvider.overrideWithValue(mockBlueskyService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final mockPosts = List.generate(
    10,
    (i) => Post(
      author: Actor(did: 'did$i', handle: 'handle$i'),
      text: 'text$i',
      createdAt: DateTime.now(),
    ),
  );

  test('Provider initializes, calls findTimeline, and enters AsyncData state', () async {
    when(mockBlueskyService.findTimeline(limit: 20)).thenAnswer(
      (_) async => Timeline(posts: mockPosts, cursor: 'cursor1'),
    );

    final listener = container.listen(timelineProvider, (_, __) {});

    await expectLater(
      container.read(timelineProvider.future),
      completes,
    );

    verify(mockBlueskyService.findTimeline(limit: 20)).called(1);

    expect(
      listener.read(),
      isA<AsyncData<Timeline>>().having(
        (s) => s.value!.posts.length,
        'posts.length',
        10,
      ),
    );
  });

  test('fetchNextPage calls findTimeline with cursor and adds posts to state', () async {
    when(mockBlueskyService.findTimeline(limit: 20)).thenAnswer(
      (_) async => Timeline(posts: mockPosts, cursor: 'cursor1'),
    );

    await container.read(timelineProvider.future);

    final newMockPosts = List.generate(
      5,
      (i) => Post(
        author: Actor(did: 'new_did$i', handle: 'new_handle$i'),
        text: 'new_text$i',
        createdAt: DateTime.now(),
      ),
    );

    when(mockBlueskyService.findTimeline(cursor: 'cursor1', limit: 20)).thenAnswer(
      (_) async => Timeline(posts: newMockPosts, cursor: 'cursor2'),
    );

    await container.read(timelineProvider.notifier).fetchNextPage();

    verify(mockBlueskyService.findTimeline(cursor: 'cursor1', limit: 20)).called(1);

    expect(
      container.read(timelineProvider).value!.posts.length,
      15,
    );
    expect(
      container.read(timelineProvider).value!.cursor,
      'cursor2',
    );
  });
}
