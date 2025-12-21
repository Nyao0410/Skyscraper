import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Map<String, String>> _feeds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    try {
      final feeds = await _service.getSavedFeeds();
      if (mounted) {
        setState(() {
          _feeds = feeds;
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
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(feed['name']![0], style: const TextStyle(color: Colors.blue))
                          : null,
                    ),
                    title: Text(feed['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(feed['desc']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () => widget.onFeedSelected(feed['name']!, feed['uri']!),
                  );
                },
              ),
      ),
    );
  }
}
