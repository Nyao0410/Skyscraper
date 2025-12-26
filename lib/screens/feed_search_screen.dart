import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(l10n.error_with_message(e.toString()))),
      );
    }
  }

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(l10n.error_with_message(e.toString()))),
      );
    }
  }

  Future<void> _addItem(dynamic item, String type) async {
    final l10n = AppLocalizations.of(context);
    try {
      final uri = item.uri.toString();
      final name = type == 'feed' ? item.displayName : item.name;
      await _service.addSavedItem(uri, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feed_search_added(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_with_message(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feed_search_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.feed_search_tab_feeds),
            Tab(text: l10n.feed_search_tab_lists),
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
                    hintText: l10n.feed_search_hint,
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
                            leading: kIsWeb
                                ? ClipOval(
                                    child: feed.avatar != null && feed.avatar!.isNotEmpty
                                        ? Image.network(
                                            feed.avatar!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 40,
                                              height: 40,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.rss_feed),
                                            ),
                                          )
                                        : Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.rss_feed),
                                          ),
                                  )
                                : CircleAvatar(
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
                      leading: kIsWeb
                          ? ClipOval(
                              child: list.avatar != null && list.avatar!.isNotEmpty
                                  ? Image.network(
                                      list.avatar!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.list),
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.list),
                                    ),
                            )
                          : CircleAvatar(
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
