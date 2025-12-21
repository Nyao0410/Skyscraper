import 'package:flutter/material.dart';
import '../utils/avatar_provider.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import '../widgets/media_grid.dart';
import '../utils/feed_utils.dart';
import 'thread_screen.dart';
import 'profile_screen.dart';
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
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('タイムライン', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('投稿がありません', style: TextStyle(color: Colors.grey)),
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
                      return _buildPostItem(post);
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

  Widget _buildPostItem(PostItem post) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ThreadScreen(postUri: post.uri)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.repostedBy != null)
              Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${post.repostedBy} さんがリポスト',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen(actor: post.handle)),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: avatarImageProvider(post.avatar),
                    child: post.avatar == null ? const Icon(Icons.person) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: post.author,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' @${post.handle}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinkifiedText(
                        text: post.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),
                      ),
                      if (post.quotedPost != null) _buildQuotedPost(post.quotedPost!),
                      if (post.media.isNotEmpty) MediaGrid(media: post.media),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, false, () => _showReplyDialog(post)),
                          _buildActionIcon(
                            post.viewerRepost != null ? Icons.repeat_on : Icons.repeat,
                            post.repostCount,
                            post.viewerRepost != null,
                            () => _handleRepost(post),
                          ),
                          _buildActionIcon(
                            post.viewerLike != null ? Icons.favorite : Icons.favorite_border,
                            post.likeCount,
                            post.viewerLike != null,
                            () => _handleLike(post),
                          ),
                          _buildActionIcon(Icons.more_horiz, null, false, () => _showPostMenu(post)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedPost(PostItem quoted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(actor: quoted.handle)),
                  );
                },
                child: quoted.avatar != null
                    ? CircleAvatar(
                        radius: 10,
                        backgroundImage: avatarImageProvider(quoted.avatar),
                      )
                    : const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quoted.author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinkifiedText(
            text: quoted.text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          if (quoted.media.isNotEmpty) MediaGrid(media: quoted.media),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, int? count, bool isActive, VoidCallback onTap) {
    Color iconColor = Colors.grey.shade600;
    if (isActive) {
      if (icon == Icons.favorite || icon == Icons.favorite_border) {
        iconColor = Colors.pink;
      } else if (icon == Icons.repeat || icon == Icons.repeat_on) {
        iconColor = Colors.green;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count > 0 ? count.toString() : '',
              style: TextStyle(color: iconColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());
    if (diff.inMinutes < 1) return '今';
    if (diff.inHours < 1) return '${diff.inMinutes}分';
    if (diff.inDays < 1) return '${diff.inHours}時間';
    return '${time.month}/${time.day}';
  }

  void _handleLike(PostItem post) async {
    try {
      if (post.viewerLike != null) {
        await _service.delete(post.viewerLike!);
      } else {
        await _service.like(post.id, post.uri);
      }
      _fetchTimeline();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  void _handleRepost(PostItem post) async {
    try {
      if (post.viewerRepost != null) {
        await _service.delete(post.viewerRepost!);
      } else {
        await _service.repost(post.id, post.uri);
      }
      _fetchTimeline();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  void _showPostMenu(PostItem post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: const Text('引用して投稿'),
              onTap: () {
                Navigator.pop(context);
                _showQuoteDialog(post);
              },
            ),
            if (post.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _service.delete(post.uri, cid: post.id);
                  _fetchTimeline();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('テキストをコピー'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewPostScreen(replyTo: post)),
    );
    if (result == true) {
      _fetchTimeline();
    }
  }

  void _showQuoteDialog(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewPostScreen(quoteOf: post)),
    );
    if (result == true) {
      _fetchTimeline();
    }
  }
}
