import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import 'thread_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _service = BlueskyService();
  late TextEditingController _searchController;
  late TabController _tabController;
  
  List<PostItem> _postResults = [];
  List<dynamic> _userResults = [];
  bool _loading = false;
  
  // Filters
  DateTime? _since;
  DateTime? _until;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    try {
      if (_tabController.index == 0) {
        // Search Posts
        final results = await _service.searchPosts(
          query,
          since: _since?.toIso8601String(),
          until: _until?.toIso8601String(),
        );
        setState(() => _postResults = results);
      } else {
        // Search Users
        final results = await _service.searchActors(query);
        setState(() => _userResults = results);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('検索エラー: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _since != null && _until != null
          ? DateTimeRange(start: _since!, end: _until!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _since = picked.start;
        _until = picked.end;
      });
      if (_searchController.text.isNotEmpty) _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '検索ワード、#タグ、@ユーザー...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          if (_since != null || _until != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.red),
              onPressed: () {
                setState(() {
                  _since = null;
                  _until = null;
                });
                if (_searchController.text.isNotEmpty) _performSearch();
              },
              tooltip: 'フィルターをクリア',
            ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: (_since != null) ? Colors.blue : Colors.grey),
            onPressed: _selectDateRange,
            tooltip: '期間指定',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '投稿'),
            Tab(text: 'ユーザー'),
          ],
          onTap: (_) {
            if (_searchController.text.isNotEmpty) _performSearch();
          },
        ),
      ),
      body: Column(
        children: [
          if (_since != null && _until != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '期間: ${_since!.year}/${_since!.month}/${_since!.day} 〜 ${_until!.year}/${_until!.month}/${_until!.day}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostResults(),
                      _buildUserResults(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostResults() {
    if (_postResults.isEmpty) {
      return const Center(child: Text('投稿が見つかりませんでした'));
    }
    return ListView.separated(
      itemCount: _postResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return const Center(child: Text('ユーザーが見つかりませんでした'));
    }
    return ListView.separated(
      itemCount: _userResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _userResults[index];
        final avatar = user.avatar;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
            child: avatar == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user.displayName ?? user.handle),
          subtitle: Text('@${user.handle}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(actor: user.handle)),
            );
          },
        );
      },
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
        child: Row(
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
                radius: 20,
                backgroundImage: post.avatar != null ? CachedNetworkImageProvider(post.avatar!) : null,
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
                        child: Text(
                          post.author,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Text('@${post.handle}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  LinkifiedText(text: post.text, style: const TextStyle(fontSize: 14)),
                  if (post.media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: post.media.first.url, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
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
