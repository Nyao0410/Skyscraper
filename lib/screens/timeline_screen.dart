import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import 'thread_screen.dart';
import 'profile_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _service = BlueskyService();
  List<PostItem> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      final posts = await _service.getTimeline();
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムライン', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTimeline,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('投稿がありません', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _posts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return _buildPostItem(post);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(),
        backgroundColor: const Color(0xFF00C300),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
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
                radius: 24,
                backgroundImage: post.avatar != null
                    ? CachedNetworkImageProvider(post.avatar!)
                    : null,
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
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: post.author,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              TextSpan(
                                text: ' @${post.handle}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinkifiedText(
                    text: post.text,
                    style: const TextStyle(fontSize: 15, height: 1.3),
                    linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),
                  ),
                  if (post.quotedPost != null) _buildQuotedPost(post.quotedPost!),
                  if (post.media.isNotEmpty) _buildMediaGrid(post.media),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, () => _showReplyDialog(post)),
                      _buildActionIcon(Icons.repeat, post.repostCount, () => _handleRepost(post)),
                      _buildActionIcon(Icons.favorite_border, post.likeCount, () => _handleLike(post)),
                      _buildActionIcon(Icons.more_horiz, null, () => _showPostMenu(post)),
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

  Widget _buildQuotedPost(PostItem quoted) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(actor: quoted.handle)),
                  );
                },
                child: quoted.avatar != null
                    ? CircleAvatar(
                        radius: 10,
                        backgroundImage: CachedNetworkImageProvider(quoted.avatar!),
                      )
                    : const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quoted.author,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinkifiedText(
            text: quoted.text,
            style: const TextStyle(fontSize: 14),
          ),
          if (quoted.media.isNotEmpty) _buildMediaGrid(quoted.media),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaItem> media) {
    if (media.isEmpty) return const SizedBox.shrink();
    debugPrint('Building media grid for ${media.length} items');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: media.length == 1
            ? _buildMediaItem(media.first, isSingle: true)
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.0,
                children: media.map((m) => _buildMediaItem(m)).toList(),
              ),
      ),
    );
  }

  Widget _buildMediaItem(MediaItem item, {bool isSingle = false}) {
    return AspectRatio(
      aspectRatio: isSingle ? 16 / 9 : 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) {
              debugPrint('Error loading image: $url, error: $error');
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
          if (item.type == MediaType.video)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, int? count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count > 0 ? count.toString() : '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
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

  void _handleLike(PostItem post) async {
    try {
      await _service.like(post.id, post.uri);
      _fetchTimeline();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  void _handleRepost(PostItem post) async {
    try {
      await _service.repost(post.id, post.uri);
      _fetchTimeline();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  void _showPostMenu(PostItem post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: const Text('引用して投稿'),
              onTap: () {
                Navigator.pop(context);
                _showQuoteDialog(post);
              },
            ),
            if (post.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _service.delete(post.uri);
                  _fetchTimeline();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('テキストをコピー'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(PostItem post) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('@${post.handle} への返信'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '返信を書き込む...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await _service.reply(post, controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchTimeline();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('返信しました')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
                }
              }
            },
            child: const Text('返信'),
          ),
        ],
      ),
    );
  }

  void _showQuoteDialog(PostItem post) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('引用投稿'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuotedPost(post),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'コメントを追加...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await _service.quote(post, controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchTimeline();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('引用投稿しました')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
                }
              }
            },
            child: const Text('投稿'),
          ),
        ],
      ),
    );
  }

  void _showPostDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規投稿'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'いまどうしてる？'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _service.post(controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchTimeline();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C300)),
            child: const Text('投稿', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
