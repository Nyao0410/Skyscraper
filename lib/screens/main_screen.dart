import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';
import '../models/post_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_screen.dart';
import 'talk_list_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'drafts_screen.dart';
import 'new_post_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default to 'Talk' (index 1)
  final _service = BlueskyService();
  final _db = DatabaseService();
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _updateDraftCount();
  }

  Future<void> _updateDraftCount() async {
    final count = await _db.getDraftCount();
    if (mounted) {
      setState(() {
        _draftCount = count;
      });
    }
  }
  
  void _navigateToChat(String name, String uri) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailWrapper(feedName: name, feedUri: uri),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      TalkListScreen(onFeedSelected: _navigateToChat),
      const SearchScreen(),
      const NotificationsScreen(),
      _buildOtherScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _updateDraftCount();
        },
        selectedItemColor: const Color(0xFF00C300),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'ホーム'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'トーク'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: '検索'),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: '通知'),
          BottomNavigationBarItem(
            icon: Badge(
              label: _draftCount > 0 ? Text(_draftCount.toString()) : null,
              isLabelVisible: _draftCount > 0,
              child: const Icon(Icons.more_horiz),
            ),
            label: 'その他',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('その他')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _service.avatar != null
                  ? CachedNetworkImageProvider(_service.avatar!)
                  : null,
              child: _service.avatar == null ? const Icon(Icons.person) : null,
            ),
            title: Text(_service.handle ?? 'ユーザー'),
            subtitle: Text(_service.did ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('下書き・予約投稿'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DraftsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _service.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChatDetailWrapper extends StatefulWidget {
  final String feedName;
  final String feedUri;

  const ChatDetailWrapper({super.key, required this.feedName, required this.feedUri});

  @override
  State<ChatDetailWrapper> createState() => _ChatDetailWrapperState();
}

class _ChatDetailWrapperState extends State<ChatDetailWrapper> {
  final _service = BlueskyService();
  List<PostItem> _feed = [];
  String? _cursor;
  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    // 1. Load from cache first
    try {
      final cachedPosts = await _service.getCachedCustomFeed(widget.feedUri);
      if (cachedPosts.isNotEmpty && mounted) {
        setState(() {
          _feed = cachedPosts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached feed: $e');
    }

    // 2. Fetch from network
    try {
      final response = await _service.getCustomFeed(widget.feedUri);
      if (mounted) {
        setState(() {
          _feed = response.posts;
          _cursor = response.cursor;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (_feed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('フィードの取得に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      final response = await _service.getCustomFeed(widget.feedUri);
      setState(() {
        _feed = response.posts;
        _cursor = response.cursor;
        _refreshing = false;
      });
    } catch (e) {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _cursor == null) return;
    
    setState(() => _loadingMore = true);
    try {
      final response = await _service.getCustomFeed(widget.feedUri, cursor: _cursor);
      if (mounted) {
        setState(() {
          _feed.addAll(response.posts);
          _cursor = response.cursor;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _handleSendMessage(String text) async {
    try {
      await _service.post(text);
      _handleRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChatScreen(
      title: widget.feedName,
      messages: _feed,
      isRefreshing: _refreshing,
      isLoadingMore: _loadingMore,
      onRefresh: _handleRefresh,
      onLoadMore: _handleLoadMore,
      onSendMessage: _handleSendMessage,
      onLike: (item) async {
        await _service.like(item.id, item.uri);
        _handleRefresh();
      },
      onRepost: (item) async {
        await _service.repost(item.id, item.uri);
        _handleRefresh();
      },
      onDelete: (item) async {
        await _service.delete(item.uri);
        _handleRefresh();
      },
      onReply: (item) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPostScreen(replyTo: item)),
        );
        if (result == true) _handleRefresh();
      },
      onQuote: (item) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPostScreen(quoteOf: item)),
        );
        if (result == true) _handleRefresh();
      },
    );
  }
}
