import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import 'thread_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String actor; // handle or DID
  const ProfileScreen({super.key, required this.actor});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = BlueskyService();
  dynamic _profile;
  List<PostItem> _feed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getProfile(widget.actor);
      final feed = await _service.getAuthorFeed(widget.actor);
      if (mounted) {
        setState(() {
          _profile = profile;
          _feed = feed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('プロフィールが見つかりませんでした'))
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = _feed[index];
                          return _buildPostItem(post);
                        },
                        childCount: _feed.length,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _profile.banner != null
            ? CachedNetworkImage(imageUrl: _profile.banner!, fit: BoxFit.cover)
            : Container(color: Colors.blue.shade200),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: _profile.avatar != null
                      ? CachedNetworkImageProvider(_profile.avatar!)
                      : null,
                  child: _profile.avatar == null ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('フォロー'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile.displayName ?? _profile.handle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${_profile.handle}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (_profile.description != null && _profile.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            LinkifiedText(
              text: _profile.description!,
              style: const TextStyle(fontSize: 15),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat('${_profile.followsCount}', 'フォロー'),
              const SizedBox(width: 20),
              _buildStat('${_profile.followersCount}', 'フォロワー'),
              const SizedBox(width: 20),
              _buildStat('${_profile.postsCount}', '投稿'),
            ],
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Row(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // TimelineScreenからコピー（共通化が望ましい）
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
            CircleAvatar(
              radius: 24,
              backgroundImage: post.avatar != null
                  ? CachedNetworkImageProvider(post.avatar!)
                  : null,
              child: post.avatar == null ? const Icon(Icons.person) : null,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '@${post.handle}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  LinkifiedText(text: post.text, style: const TextStyle(fontSize: 15)),
                  if (post.media.isNotEmpty) _buildMediaGrid(post.media),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
                      Icon(Icons.repeat, size: 18, color: Colors.grey.shade600),
                      Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                      Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaItem> media) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(imageUrl: media.first.url, fit: BoxFit.cover),
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
