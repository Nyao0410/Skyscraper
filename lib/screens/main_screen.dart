import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../models/post_item.dart';
import 'chat_screen.dart';
import 'talk_list_screen.dart';
import 'timeline_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default to 'Talk' (index 1)
  final _service = BlueskyService();
  
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
      const Center(child: Text('ホーム (準備中)')),
      TalkListScreen(onFeedSelected: _navigateToChat),
      const TimelineScreen(),
      const Center(child: Text('ニュース (準備中)')),
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
        },
        selectedItemColor: const Color(0xFF00C300),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'トーク'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), activeIcon: Icon(Icons.access_time_filled), label: 'タイムライン'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper), label: 'ニュース'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'その他'),
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
            leading: const Icon(Icons.person),
            title: Text(_service.handle ?? 'ユーザー'),
            subtitle: Text(_service.did ?? ''),
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
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final posts = await _service.getCustomFeed(widget.feedUri);
      if (mounted) {
        setState(() {
          _feed = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('フィードの取得に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      final posts = await _service.getCustomFeed(widget.feedUri);
      setState(() {
        _feed = posts;
        _refreshing = false;
      });
    } catch (e) {
      setState(() => _refreshing = false);
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
      onRefresh: _handleRefresh,
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
      onReply: (item) => _showPostDialog(item, isReply: true),
      onQuote: (item) => _showPostDialog(item, isQuote: true),
    );
  }

  void _showPostDialog(PostItem item, {bool isReply = false, bool isQuote = false}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReply ? '返信' : '引用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isMe ? '自分の投稿' : '${item.author} さんの投稿',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isReply ? '返信を入力...' : 'コメントを入力...',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              
              try {
                if (isReply) {
                  await _service.reply(item, text);
                } else if (isQuote) {
                  await _service.quote(item, text);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isReply ? '返信しました' : '引用しました')),
                  );
                  _handleRefresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('投稿'),
          ),
        ],
      ),
    );
  }
}
