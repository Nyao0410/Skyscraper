import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/avatar_provider.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import '../widgets/media_grid.dart';
import '../utils/feed_utils.dart';
import 'thread_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String actor; // handle or DID
  const ProfileScreen({super.key, required this.actor});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _service = BlueskyService();
  dynamic _profile;
  List<dynamic> _currentData = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchFeedForTab(_tabController.index);
  }

  Future<void> _fetchData() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final profile = await _service.getProfile(widget.actor);
      if (mounted) {
        setState(() {
          _profile = profile;
        });
        _fetchFeedForTab(0); // Initial tab
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  Future<void> _fetchFeedForTab(int index, {bool forceRefresh = false}) async {
    final l10n = AppLocalizations.of(context);
    // 1. Load from cache first
    if (!forceRefresh) {
      try {
        List<dynamic> cachedData = [];
        switch (index) {
          case 0:
            cachedData = await _service.getCachedAuthorFeed(widget.actor, filter: 'posts_no_replies');
            break;
          case 1:
            cachedData = await _service.getCachedAuthorFeed(widget.actor, filter: 'posts_with_replies');
            break;
          case 2:
            cachedData = await _service.getCachedAuthorFeed(widget.actor, filter: 'posts_with_media');
            break;
          case 3:
            cachedData = await _service.getCachedAuthorFeed(widget.actor, filter: 'posts_with_video');
            break;
        }
        if (cachedData.isNotEmpty && mounted) {
          setState(() {
            _currentData = cachedData;
            _loading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading cached profile feed: $e');
      }
    }

    // 2. Fetch from network
    setState(() => _loading = _currentData.isEmpty);
    try {
      List<dynamic> data = [];
      switch (index) {
        case 0: // 投稿
          data = await _service.getAuthorFeedWithFilter(widget.actor, filter: 'posts_no_replies');
          break;
        case 1: // 返信
          data = await _service.getAuthorFeedWithFilter(widget.actor, filter: 'posts_with_replies');
          break;
        case 2: // メディア
          data = await _service.getAuthorFeedWithFilter(widget.actor, filter: 'posts_with_media');
          break;
        case 3: // ビデオ
          data = await _service.getAuthorFeedWithFilter(widget.actor, filter: 'posts_with_video');
          break;
        case 4: // フィード
          data = await _service.getActorFeeds(widget.actor);
          break;
        default:
          data = [];
      }
      if (mounted) {
        setState(() {
          _currentData = mergePosts(_currentData, data, atTop: true);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (_currentData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SelectionArea(
        child: _profile == null && _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? Center(child: Text(l10n.profile_not_found))
                : RefreshIndicator(
                    onRefresh: () => _fetchFeedForTab(_tabController.index, forceRefresh: true),
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(),
                      SliverToBoxAdapter(child: _buildProfileHeader()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabs: [
                              Tab(text: l10n.profile_tab_posts),
                              Tab(text: l10n.profile_tab_replies),
                              Tab(text: l10n.profile_tab_media),
                              Tab(text: l10n.profile_tab_video),
                              Tab(text: l10n.profile_tab_feeds),
                            ],
                          ),
                        ),
                      ),
                      if (_loading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_currentData.isEmpty)
                        SliverFillRemaining(
                          child: Center(child: Text(l10n.profile_no_data)),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _currentData[index];
                              if (item is PostItem) {
                                return _buildPostItem(item);
                              } else {
                                // FeedGeneratorView or ListView
                                return _buildGenericItem(item);
                              }
                            },
                            childCount: _currentData.length,
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildGenericItem(dynamic item) {
    final l10n = AppLocalizations.of(context);
    // item could be FeedGeneratorView or ListView
    final String title = item.displayName ?? l10n.unknown;
    final String? description = item.description;
    final String? avatar = item.avatar;
    final String? creator = item.creator?.handle;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarImageProvider(avatar),
        child: avatar == null ? const Icon(Icons.rss_feed) : null,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creator != null) Text('by @$creator', style: const TextStyle(fontSize: 12, color: Colors.blue)),
          if (description != null)
            LinkifiedText(
              text: description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
              linkStyle: const TextStyle(color: Colors.blue),
            ),
        ],
      ),
      onTap: () {
        // Handle navigation to feed or list if needed
      },
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _profile.banner != null
            ? CachedNetworkImage(imageUrl: _profile.banner!, fit: BoxFit.cover)
            : Container(color: Colors.blue.shade200),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showPostSearch,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'share', child: Text(l10n.share)),
            if (_profile.viewer?.muted == true)
              PopupMenuItem(value: 'unmute', child: Text(l10n.profile_unmute))
            else
              PopupMenuItem(value: 'mute', child: Text(l10n.profile_mute)),
            if (_profile.viewer?.blocking == null)
              PopupMenuItem(value: 'block', child: Text(l10n.profile_block, style: const TextStyle(color: Colors.red)))
            else
              PopupMenuItem(value: 'unblock', child: Text(l10n.profile_unblock)),
          ],
        ),
      ],
    );
  }

  void _showPostSearch() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profile_search_posts_title(_profile.handle)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.profile_search_posts_hint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final query = controller.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _performPostSearch(query);
              }
            },
            child: Text(l10n.search),
          ),
        ],
      ),
    );
  }

  Future<void> _performPostSearch(String query) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      // Search inside this user's posts for the given query.
      final results = await _service.searchAuthorPosts(query, _profile.handle);
      if (mounted) {
        setState(() {
          _currentData = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    final l10n = AppLocalizations.of(context);
    try {
      switch (action) {
        case 'share':
          // Simple share (copy to clipboard or similar)
          final url = 'https://bsky.app/profile/${_profile.handle}';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profile_url_label(url))));
          break;
        case 'mute':
          await _service.mute(_profile.did);
          _fetchData();
          break;
        case 'unmute':
          await _service.unmute(_profile.did);
          _fetchData();
          break;
        case 'block':
          await _service.block(_profile.did);
          _fetchData();
          break;
        case 'unblock':
          await _service.unblock(_profile.viewer!.blocking!.toString());
          _fetchData();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  Widget _buildProfileHeader() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: isDark ? Colors.black : Colors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: avatarImageProvider(_profile.avatar),
                  child: _profile.avatar == null ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
              _buildFollowButton(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile.displayName ?? _profile.handle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${_profile.handle}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (_profile.description != null && _profile.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            LinkifiedText(
              text: _profile.description!,
              style: const TextStyle(fontSize: 15),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat('${_profile.followsCount}', l10n.profile_follows, () {
                _showUserList(l10n.profile_follows, () => _service.getFollows(widget.actor));
              }),
              const SizedBox(width: 20),
              _buildStat('${_profile.followersCount}', l10n.profile_followers, () {
                _showUserList(l10n.profile_followers, () => _service.getFollowers(widget.actor));
              }),
              const SizedBox(width: 20),
              _buildStat('${_profile.postsCount}', l10n.profile_tab_posts, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = _profile.did == _service.did;
    if (isMe) {
      return OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(l10n.profile_edit),
      );
    }

    final isFollowing = _profile.viewer?.following != null;

    return ElevatedButton(
      onPressed: () async {
        try {
          if (isFollowing) {
            await _service.unfollow(_profile.viewer!.following!.toString());
          } else {
            await _service.follow(_profile.did);
          }
          _fetchData(); // Refresh profile
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing 
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : (isDark ? Colors.white : Colors.black),
        foregroundColor: isFollowing
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.black : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(isFollowing ? l10n.profile_unfollow : l10n.profile_follow),
    );
  }

  Widget _buildStat(String count, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  void _showUserList(String title, Future<List<dynamic>> Function() fetcher) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetcher(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(l10n.error_with_message(snapshot.error.toString())));
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return Center(child: Text(l10n.no_results));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarImageProvider(user.avatar),
                          child: user.avatar == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user.displayName ?? user.handle),
                        subtitle: Text('@${user.handle}'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen(actor: user.did)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TimelineScreenからコピー（共通化が望ましい）
  Widget _buildPostItem(PostItem post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarImageProvider(post.avatar),
                  child: post.avatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.author,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '@${post.handle}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      LinkifiedText(
                        text: post.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        ),
                      ),
                      if (post.media.isNotEmpty) MediaGrid(media: post.media),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
                          Icon(Icons.repeat, size: 18, color: Colors.grey.shade600),
                          Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                          Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade600),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());
    if (diff.inMinutes < 1) return '今';
    if (diff.inHours < 1) return '${diff.inMinutes}分';
    if (diff.inDays < 1) return '${diff.inHours}時間';
    return '${time.month}/${time.day}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
