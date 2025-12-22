import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/avatar_provider.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import '../widgets/post_widget.dart';
import '../utils/feed_utils.dart';

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
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      // Defer fetching data until after the first dependency resolution so
      // that `AppLocalizations.of(context)` and other inherited widgets
      // are available.
      _fetchData();
    }
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
                            indicatorColor: const Color(0xFF00C300),
                            labelColor: const Color(0xFF00C300),
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                                return PostWidget(
                                  post: item,
                                  onPostUpdated: _fetchData,
                                );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineGreen = const Color(0xFF00C300);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_profile.banner != null)
              CachedNetworkImage(imageUrl: _profile.banner!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineGreen.withValues(alpha: 0.2),
                      isDark ? const Color(0xFF121212) : Colors.white,
                    ],
                  ),
                ),
              ),
            // Gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? const Color(0xFF121212) : Colors.white).withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: lineGreen, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                      backgroundImage: avatarImageProvider(_profile.avatar),
                      child: _profile.avatar == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _profile.displayName ?? _profile.handle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '@${_profile.handle}',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (_profile.description != null && _profile.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LinkifiedText(
              text: _profile.description!,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildFollowButton(),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('${_profile.followsCount}', l10n.profile_follows, () {
                _showUserList(l10n.profile_follows, () => _service.getFollows(widget.actor));
              }),
              _buildStat('${_profile.followersCount}', l10n.profile_followers, () {
                _showUserList(l10n.profile_followers, () => _service.getFollowers(widget.actor));
              }),
              _buildStat('${_profile.postsCount}', l10n.profile_tab_posts, null),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFollowButton() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineGreen = const Color(0xFF00C300);
    final isMe = _profile.did == _service.did;
    
    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.edit),
            label: Text(l10n.profile_edit, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    final isFollowing = _profile.viewer?.following != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
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
                ? (isDark ? Colors.grey[800] : Colors.grey[200])
                : lineGreen,
            foregroundColor: isFollowing
                ? (isDark ? Colors.white : Colors.black)
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            isFollowing ? l10n.profile_unfollow : l10n.profile_follow,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String count, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Column(
        children: [
          _tabBar,
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
