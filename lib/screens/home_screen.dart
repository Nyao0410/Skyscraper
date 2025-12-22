import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
import '../services/bluesky_service.dart';
import 'timeline_screen.dart';
import 'profile_screen.dart';
import 'new_post_screen.dart';
import 'notifications_screen.dart';
import 'chat_detail_wrapper.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = BlueskyService();
  dynamic _profile;
  bool _loading = true;
  List<Map<String, String>> _customFeeds = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_service.did == null) return;
    setState(() => _loading = true);
    try {
      final profile = await _service.getProfile(_service.did!);
      final feeds = await _service.getSavedFeeds();
      
      // Fetch unread counts for each feed
      final List<Map<String, String>> feedsWithUnread = [];
      for (var feed in feeds) {
        final unreadCount = await _service.getUnreadCount(feed['uri']!);
        feedsWithUnread.add({
          ...feed,
          'unreadCount': unreadCount.toString(),
        });
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _customFeeds = feedsWithUnread;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching home data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineGreen = const Color(0xFF00C300);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, isDark, lineGreen),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProfileInfo(context, isDark),
                        _buildActionButtons(context, lineGreen),
                        const Divider(height: 1, thickness: 1),
                        _buildMenuItems(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, Color lineGreen) {
    final l10n = AppLocalizations.of(context);
    final avatarUrl = _profile?.avatar;
    final displayName = _profile?.displayName ?? _service.handle ?? l10n.user;
    final description = _profile?.description ?? l10n.home_welcome;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineGreen.withValues(alpha: 0.15),
                isDark ? const Color(0xFF121212) : Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lineGreen, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: avatarImageProvider(avatarUrl),
                    child: avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(l10n.profile_handle, '@${_service.handle}', isDark),
          const Divider(height: 16),
          _buildInfoRow(l10n.profile_did, _service.did ?? '', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color lineGreen) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewPostScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lineGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_note),
              label: Text(l10n.home_post_button, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          _buildCircleActionButton(Icons.search, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          }),
          const SizedBox(width: 8),
          _buildCircleActionButton(Icons.notifications_none, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            l10n.home_menu_title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        _buildMenuItem(
          icon: Icons.timeline,
          title: l10n.home_timeline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimelineScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.person_outline,
          title: l10n.home_my_profile,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(actor: _service.did!)),
            );
          },
        ),
        if (_customFeeds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              l10n.home_saved_feeds,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ..._customFeeds.where((f) => f['uri'] != 'following').map((feed) => _buildMenuItem(
            icon: Icons.rss_feed,
            title: feed['name'] ?? l10n.home_unknown_feed,
            badge: feed['unreadCount'],
            onTap: () async {
              // Navigate directly to the talk room for this feed
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailWrapper(feedName: feed['name'] ?? l10n.home_talk, feedUri: feed['uri']!),
                ),
              );
              _fetchData(); // Refresh unread counts when returning
            },
          )),
        ],
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, String? badge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge != '0')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00C300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

