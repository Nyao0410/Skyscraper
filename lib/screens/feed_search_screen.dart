import 'package:flutter/material.dart';
import '../utils/avatar_provider.dart';
import '../services/bluesky_service.dart';

class FeedSearchScreen extends StatefulWidget {
  const FeedSearchScreen({super.key});

  @override
  State<FeedSearchScreen> createState() => _FeedSearchScreenState();
}

class _FeedSearchScreenState extends State<FeedSearchScreen> with SingleTickerProviderStateMixin {
  final _service = BlueskyService();
  final _controller = TextEditingController();
  late TabController _tabController;
  
  List<dynamic> _feedResults = [];
  List<dynamic> _myLists = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _myLists.isEmpty) {
        _loadMyLists();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMyLists() async {
    setState(() => _loading = true);
    try {
      final lists = await _service.getLists(_service.did!);
      if (!mounted) return;
      setState(() {
        _myLists = lists;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リスト取得エラー: $e')),
      );
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    try {
      final results = await _service.searchFeeds(query);
      if (!mounted) return;
      setState(() {
        _feedResults = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('検索エラー: $e')),
      );
    }
  }

  Future<void> _addItem(dynamic item, String type) async {
    try {
      final uri = item.uri.toString();
      final name = type == 'feed' ? item.displayName : item.name;
      await _service.addSavedItem(uri, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name を追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('追加エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('追加'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feed検索'),
            Tab(text: '自分のリスト'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Feed Search Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Feedを検索...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _search,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              Expanded(
                child: _loading && _feedResults.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _feedResults.length,
                        itemBuilder: (context, index) {
                          final feed = _feedResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: avatarImageProvider(feed.avatar),
                              child: feed.avatar == null ? const Icon(Icons.rss_feed) : null,
                            ),
                            title: Text(feed.displayName),
                            subtitle: Text(
                              feed.description ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addItem(feed, 'feed'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // My Lists Tab
          _loading && _myLists.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _myLists.length,
                  itemBuilder: (context, index) {
                    final list = _myLists[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarImageProvider(list.avatar),
                        child: list.avatar == null ? const Icon(Icons.list) : null,
                      ),
                      title: Text(list.name),
                      subtitle: Text(
                        list.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _addItem(list, 'list'),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
