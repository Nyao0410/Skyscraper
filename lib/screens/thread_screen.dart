import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import 'profile_screen.dart';

class ThreadScreen extends StatefulWidget {
  final String postUri;
  const ThreadScreen({super.key, required this.postUri});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _service = BlueskyService();
  dynamic _thread;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchThread();
  }

  Future<void> _fetchThread() async {
    setState(() => _loading = true);
    try {
      debugPrint('Fetching thread for: ${widget.postUri}');
      final thread = await _service.getPostThread(widget.postUri);
      debugPrint('Thread fetched successfully: ${thread.runtimeType}');
      if (mounted) {
        setState(() {
          _thread = thread;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching thread: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スレッド', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _thread == null
              ? const Center(child: Text('スレッドが見つかりませんでした'))
              : RefreshIndicator(
                  onRefresh: _fetchThread,
                  child: ListView(
                    children: _buildThreadItems(_thread),
                  ),
                ),
    );
  }

  List<Widget> _buildThreadItems(dynamic thread) {
    try {
      List<Widget> items = [];
      
      // threadがUnion型の場合、中身を取り出す
      dynamic threadView = _unwrapUnion(thread);
      if (threadView == null) {
        return [const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('スレッドデータを解析できませんでした'),
        ))];
      }

      // 1. Parents (if any)
      _addParents(thread, items);

      // 2. Main Post
      if (_hasPostField(threadView)) {
        final mainPost = PostItem.fromFeedView(threadView, _service.handle);
        items.add(_buildMainPost(mainPost));
        items.add(const Divider(height: 1, thickness: 1));
      } else {
        items.add(const ListTile(title: Text('この投稿は表示できません')));
      }

      // 3. Replies
      if (_hasRepliesField(threadView)) {
        final dynamic replies = (threadView is Map) ? threadView['replies'] : threadView.replies;
        if (replies != null && replies is List) {
          for (final reply in replies) {
            _addReply(reply, items, 0);
          }
        }
      }

      return items;
    } catch (e) {
      debugPrint('Error building thread items: $e');
      return [Center(child: Text('表示エラーが発生しました: $e'))];
    }
  }

  dynamic _unwrapUnion(dynamic union) {
    if (union == null) return null;
    try {
      // すでにMapの場合はそのまま返す
      if (union is Map) return union;

      // toJson()を試みる
      try {
        final map = union.toJson();
        if (map.containsKey('post')) return map;
        if (map.containsKey('data')) return map['data'];
      } catch (_) {}

      dynamic result;
      // maybeWhenを試みる
      try {
        union.maybeWhen(
          threadViewPost: (data) => result = data,
          viewRecord: (data) => result = data,
          orElse: () {},
        );
      } catch (_) {
        // それでもダメなら、dataプロパティを直接探す
        try {
          result = union.data;
        } catch (_) {}
      }
      
      return result ?? union;
    } catch (e) {
      debugPrint('Unwrap error: $e');
      return union;
    }
  }

  void _addParents(dynamic thread, List<Widget> items) {
    List<dynamic> parents = [];
    
    try {
      dynamic currentView = _unwrapUnion(thread);
      
      // 親投稿の取得をより柔軟にする
      dynamic getParent(dynamic view) {
        try {
          if (view is Map) return view['parent'];
          return view.parent;
        } catch (_) {
          try {
            return view.toJson()['parent'];
          } catch (_) {
            return null;
          }
        }
      }

      dynamic currentParent = getParent(currentView);
      
      while (currentParent != null) {
        dynamic parentView = _unwrapUnion(currentParent);
        if (parentView != null && _hasPostField(parentView)) {
          parents.add(parentView);
          currentParent = getParent(parentView);
        } else {
          break;
        }
      }
    } catch (e) {
      debugPrint('Error traversing parents: $e');
    }
    
    for (final p in parents.reversed) {
      try {
        final parentPost = PostItem.fromFeedView(p, _service.handle);
        items.add(_buildThreadPost(parentPost, isReply: false));
        items.add(const Divider(height: 1, indent: 50));
      } catch (e) {
        debugPrint('Error parsing parent: $e');
      }
    }
  }

  void _addReply(dynamic reply, List<Widget> items, int depth) {
    try {
      dynamic replyView = _unwrapUnion(reply);
      if (replyView == null || !_hasPostField(replyView)) return;

      final replyPost = PostItem.fromFeedView(replyView, _service.handle);
      items.add(_buildThreadPost(replyPost, isReply: true, depth: depth));
      items.add(const Divider(height: 1, indent: 50));

      if (_hasRepliesField(replyView) && depth < 3) {
        final dynamic replies = (replyView is Map) ? replyView['replies'] : replyView.replies;
        if (replies != null && replies is List) {
          for (final subReply in replies) {
            _addReply(subReply, items, depth + 1);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing reply: $e');
    }
  }

  bool _hasPostField(dynamic obj) {
    if (obj == null) return false;
    try {
      if (obj is Map) return obj.containsKey('post');
      
      // toJson()してMapとして確認するのが最も確実
      final map = obj.toJson();
      return map.containsKey('post') || (map.containsKey('data') && map['data'] is Map && map['data'].containsKey('post'));
    } catch (e) {
      // toJson()がない場合は直接プロパティを確認
      try {
        return obj.post != null;
      } catch (_) {
        return false;
      }
    }
  }

  bool _hasRepliesField(dynamic obj) {
    if (obj == null) return false;
    try {
      if (obj is Map) return obj.containsKey('replies');

      final map = obj.toJson();
      return map.containsKey('replies') || (map.containsKey('data') && map['data'] is Map && map['data'].containsKey('replies'));
    } catch (e) {
      try {
        return obj.replies != null;
      } catch (_) {
        return false;
      }
    }
  }

  Widget _buildMainPost(PostItem post) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      post.author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '@${post.handle}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Linkify(
            text: post.text,
            style: const TextStyle(fontSize: 18, height: 1.4),
            linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),
            onOpen: (link) async {
              final url = Uri.parse(link.url);
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
          ),
          if (post.quotedPost != null) _buildQuotedPost(post.quotedPost!),
          if (post.media.isNotEmpty) _buildMediaGrid(post.media),
          const SizedBox(height: 16),
          Text(
            _formatFullDate(post.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, () => _showReplyDialog(post)),
              _buildActionIcon(Icons.repeat, post.repostCount, () => _handleRepost(post)),
              _buildActionIcon(Icons.favorite_border, post.likeCount, () => _handleLike(post)),
              _buildActionIcon(Icons.share_outlined, null, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreadPost(PostItem post, {required bool isReply, int depth = 0}) {
    return InkWell(
      onTap: () {
        if (post.uri != widget.postUri) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ThreadScreen(postUri: post.uri)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: 12.0 + (depth * 16.0), top: 12, right: 12, bottom: 12),
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
                        child: Text(
                          post.author,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                  Text(
                    '@${post.handle}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Linkify(
                    text: post.text,
                    style: const TextStyle(fontSize: 14),
                    linkStyle: const TextStyle(color: Colors.blue),
                  ),
                  if (post.media.isNotEmpty) _buildMediaGrid(post.media),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, () => _showReplyDialog(post)),
                      _buildActionIcon(Icons.repeat, post.repostCount, () => _handleRepost(post)),
                      _buildActionIcon(Icons.favorite_border, post.likeCount, () => _handleLike(post)),
                      const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
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

  // Helper methods (copied from TimelineScreen for now, should be refactored later)
  Widget _buildMediaGrid(List<MediaItem> media) {
    if (media.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: media.length == 1
            ? CachedNetworkImage(imageUrl: media.first.url, fit: BoxFit.cover)
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: media.map((m) => CachedNetworkImage(imageUrl: m.url, fit: BoxFit.cover)).toList(),
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
                    ? CircleAvatar(radius: 10, backgroundImage: CachedNetworkImageProvider(quoted.avatar!))
                    : const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(quoted.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 4),
          Text(quoted.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
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
            Text(count > 0 ? count.toString() : '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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

  String _formatFullDate(DateTime time) {
    final local = time.toLocal();
    return '${local.year}/${local.month}/${local.day} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _handleLike(PostItem post) async {
    try {
      await _service.like(post.id, post.uri);
      _fetchThread();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }

  void _handleRepost(PostItem post) async {
    try {
      await _service.repost(post.id, post.uri);
      _fetchThread();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
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
          decoration: const InputDecoration(hintText: '返信を書き込む...', border: OutlineInputBorder()),
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
                  _fetchThread();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('返信しました')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
              }
            },
            child: const Text('返信'),
          ),
        ],
      ),
    );
  }
}
