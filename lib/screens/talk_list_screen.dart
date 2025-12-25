import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/avatar_provider.dart';
import '../services/bluesky_service.dart';
import 'search_screen.dart';
import 'feed_search_screen.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'dm_detail_wrapper.dart';

class TalkListScreen extends StatefulWidget {
  final Function(String name, String uri) onFeedSelected;

  const TalkListScreen({super.key, required this.onFeedSelected});

  @override
  State<TalkListScreen> createState() => _TalkListScreenState();
}

class _TalkListScreenState extends State<TalkListScreen> with SingleTickerProviderStateMixin {
  final _service = BlueskyService();
  List<Map<String, dynamic>> _feeds = [];
  List<Map<String, dynamic>> _dmConversations = [];
  bool _loading = true;
  late TabController _tabController;
  Timer? _dmPollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadFeeds();
    // Poll DM conversations periodically when DM tab is active
    _dmPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_tabController.index == 3 && !_loading) {
        _loadFeeds();
      }
    });
  }

  @override
  void dispose() {
    _dmPollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    try {
      setState(() => _loading = true);
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

      final dmConvos = await _service.getDMConversations();

      if (mounted) {
        setState(() {
          _feeds = feedsWithUnread;
          _dmConversations = dmConvos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.talk_list_fetch_error}: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredFeeds() {
    switch (_tabController.index) {
      case 1: // フィード
        return _feeds.where((f) => f['uri']!.contains('app.bsky.feed.generator') || f['uri'] == 'following').toList();
      case 2: // リスト
        return _feeds.where((f) => f['uri']!.contains('app.bsky.graph.list')).toList();
      case 3: // DM (Placeholder for now as DM API is separate)
        return [];
      case 0: // 全て
      default:
        // Combine feeds and DM conversations for "All" view.
        final List<Map<String, dynamic>> combined = [];
        combined.addAll(_feeds);
        for (final convo in _dmConversations) {
          combined.add({
            '_isDM': true,
            'name': convo['participant_handle'],
            'avatar': convo['participant_avatar'],
            'desc': convo['last_message'] ?? '',
            'indexedAt': convo['last_message_at'],
            'convo': convo,
          });
        }
        return combined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredFeeds = _getFilteredFeeds();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.talk_list_title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00C300),
              labelColor: const Color(0xFF00C300),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: l10n.talk_list_tab_all),
                Tab(text: l10n.talk_list_tab_feeds),
                Tab(text: l10n.talk_list_tab_lists),
                Tab(text: l10n.talk_list_tab_dm),
              ],
            ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeeds,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tabController.index == 3 // DM Tab
                ? _buildDMList()
                : filteredFeeds.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: filteredFeeds.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final feed = filteredFeeds[index];
                          final isDM = feed['_isDM'] == true;

                          if (isDM) {
                            final convo = feed['convo'] as Map<String, dynamic>?;
                            final avatarUrl = convo != null ? convo['participant_avatar'] : feed['avatar'];
                            final timeStr = feed['indexedAt'] != null
                                ? DateTime.parse(feed['indexedAt']!).toLocal().toString().substring(11, 16)
                                : '--:--';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: avatarImageProvider(avatarUrl),
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? const Icon(Icons.person, color: Colors.blue)
                                    : null,
                              ),
                              title: Text(convo != null ? (convo['participant_handle'] ?? l10n.unknown) : (feed['name'] ?? l10n.unknown),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                convo != null ? (convo['last_message'] ?? '') : (feed['desc'] ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              onTap: () async {
                                if (convo != null) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DMDetailWrapper(
                                        participantDid: convo['participant_did'],
                                        participantHandle: convo['participant_handle'],
                                        participantAvatar: convo['participant_avatar'],
                                        convoId: convo['id'],
                                      ),
                                    ),
                                  );
                                  _loadFeeds();
                                }
                              },
                            );
                          }

                          // Regular feed item
                          final avatarUrl = feed['avatar'];
                          final timeStr = feed['indexedAt'] != null
                              ? DateTime.parse(feed['indexedAt']!).toLocal().toString().substring(11, 16)
                              : '--:--';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: avatarImageProvider(avatarUrl),
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Text((feed['name'] ?? '')[0], style: const TextStyle(color: Colors.blue))
                                  : null,
                            ),
                            title: Text(feed['name'] ?? l10n.unknown,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              feed['uri'] == 'following'
                                  ? l10n.following_feed_desc
                                  : (feed['desc'] ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              final name = feed['name'] as String?;
                              final uri = feed['uri'] as String?;
                              if (name != null && uri != null) {
                                await widget.onFeedSelected(name, uri);
                                _loadFeeds(); // Refresh unread counts when returning
                              }
                            },
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildDMList() {
    final l10n = AppLocalizations.of(context);
    if (_dmConversations.isEmpty) return _buildEmptyState();

    return ListView.separated(
      itemCount: _dmConversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final convo = _dmConversations[index];
        final avatarUrl = convo['participant_avatar'];
        final timeStr = convo['last_message_at'] != null
            ? DateTime.parse(convo['last_message_at']!).toLocal().toString().substring(11, 16)
            : '--:--';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            backgroundImage: avatarImageProvider(avatarUrl),
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.blue)
                : null,
          ),
            title: Text(convo['participant_handle'] ?? l10n.unknown,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            convo['last_message'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DMDetailWrapper(
                  participantDid: convo['participant_did'],
                  participantHandle: convo['participant_handle'],
                  participantAvatar: convo['participant_avatar'],
                  convoId: convo['id'],
                ),
              ),
            );
            _loadFeeds();
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(l10n.empty_list, style: const TextStyle(color: Colors.grey)),
    );
  }
}
