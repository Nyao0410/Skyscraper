import 'package:flutter/material.dart';
import '../utils/avatar_provider.dart';
import '../services/bluesky_service.dart';
import 'search_screen.dart';
import 'feed_search_screen.dart';

class TalkListScreen extends StatefulWidget {
  final Function(String name, String uri) onFeedSelected;

  const TalkListScreen({super.key, required this.onFeedSelected});

  @override
  State<TalkListScreen> createState() => _TalkListScreenState();
}

class _TalkListScreenState extends State<TalkListScreen> {
  final _service = BlueskyService();
  List<Map<String, dynamic>> _feeds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    try {
      final feeds = await _service.getSavedFeeds();
      
      // Fetch unread counts for each feed
      final List<Map<String, dynamic>> feedsWithUnread = [];
      for (var feed in feeds) {
        final unreadCount = await _service.getUnreadCount(feed['uri']!);
        feedsWithUnread.add({
          ...feed,
          'unreadCount': unreadCount,
        });
      }

      if (mounted) {
        setState(() {
          _feeds = feedsWithUnread;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トーク', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedSearchScreen()),
              );
              _loadFeeds();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeeds,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: _feeds.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final feed = _feeds[index];
                  final avatarUrl = feed['avatar'];
                  final timeStr = feed['indexedAt'] != null
                      ? DateTime.parse(feed['indexedAt']!).toLocal().toString().substring(11, 16)
                      : '--:--';
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: avatarImageProvider(avatarUrl),
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(feed['name']![0], style: const TextStyle(color: Colors.blue))
                          : null,
                    ),
                    title: Text(feed['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(feed['desc']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (feed['unreadCount'] != null && feed['unreadCount'] > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              feed['unreadCount'] > 99 ? '99+' : feed['unreadCount'].toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await widget.onFeedSelected(feed['name']!, feed['uri']!);
                      _loadFeeds(); // Refresh unread counts when returning
                    },
                  );
                },
              ),
      ),
    );
  }
}
