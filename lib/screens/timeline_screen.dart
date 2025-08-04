
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skyscraper/providers/timeline_provider.dart';
import 'package:skyscraper/widgets/post_card.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ref.read(timelineProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: timeline.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (posts) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(timelineProvider.future),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final post = posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/create_post');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
