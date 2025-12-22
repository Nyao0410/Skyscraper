import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/post_widget.dart';
import '../utils/feed_utils.dart';
import 'search_screen.dart';
import 'new_post_screen.dart';

class TimelineScreen extends StatefulWidget {
  final bool showAppBar;
  const TimelineScreen({super.key, this.showAppBar = true});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _service = BlueskyService();
  final _scrollController = ScrollController();
  List<PostItem> _posts = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTimeline();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _fetchTimeline({bool forceRefresh = false}) async {
    // 1. Load from cache first for immediate display
    if (!forceRefresh) {
      try {
        final cachedPosts = await _service.getCachedTimeline();
        if (cachedPosts.isNotEmpty && mounted) {
          setState(() {
            _posts = cachedPosts;
            _loading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading cached timeline: $e');
      }
    }

    // 2. Fetch from network to update
    try {
      final response = await _service.getTimeline(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _posts = mergePosts(_posts, response.posts, atTop: true);
          _cursor = response.cursor;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline from network: $e');
      if (mounted && _posts.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _service.getTimeline(cursor: _cursor);
      if (mounted) {
        setState(() {
          _posts = mergePosts(_posts, response.posts, atTop: false);
          _cursor = response.cursor;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more timeline: $e');
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(l10n.timeline_title, style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _fetchTimeline(forceRefresh: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.timeline_no_posts, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: _posts.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = _posts[index];
                      return PostWidget(
                        post: post,
                        onPostUpdated: () => _fetchTimeline(forceRefresh: true),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPostScreen()),
          );
          if (result == true) {
            _fetchTimeline(forceRefresh: true);
          }
        },
        backgroundColor: const Color(0xFF00C300),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
