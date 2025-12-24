import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
// url_launcher not used in this file; remove unused import
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../widgets/linkified_text.dart';
import '../widgets/media_grid.dart';
import '../widgets/post_widget.dart';
import 'profile_screen.dart';
import 'new_post_screen.dart';

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
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _fetchThread();
    }
  }

  Future<void> _fetchThread() async {
    final l10n = AppLocalizations.of(context);
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
      if (!mounted) return;
      setState(() => _loading = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.thread_title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SelectionArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _thread == null
                ? Center(child: Text(l10n.thread_not_found))
                : RefreshIndicator(
                    onRefresh: _fetchThread,
                    child: ListView(
                      children: _buildThreadItems(_thread),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _buildThreadItems(dynamic thread) {
    final l10n = AppLocalizations.of(context);
    try {
      List<Widget> items = [];
      
      // threadがUnion型の場合、中身を取り出す
      dynamic threadView = _unwrapUnion(thread);
      if (threadView == null) {
        return [Center(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(l10n.thread_parse_error),
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
        items.add(ListTile(title: Text(l10n.post_not_viewable)));
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
      debugPrint('Error in _buildThreadItems: $e');
      return [
        Center(child: Text(l10n.error_with_message(e.toString())))
      ];
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
        items.add(PostWidget(
          post: parentPost,
          onPostUpdated: _fetchThread,
        ));
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
      items.add(PostWidget(
        post: replyPost,
        onPostUpdated: _fetchThread,
        leftPadding: 12.0 + (depth * 16.0),
      ));
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    l10n.timeline_reposted_by(post.repostedBy!),
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
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
                  backgroundImage: avatarImageProvider(post.avatar),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
          LinkifiedText(
            text: post.text,
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),
          ),
          if (post.quotedPost != null) _buildQuotedPost(post.quotedPost!),
          if (post.media.isNotEmpty)
            MediaGrid(
              media: post.media,
              postLabels: post.labels,
              heroTagPrefix: post.uri,
            ),
          const SizedBox(height: 16),
          Text(
            _formatFullDate(post.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, false, () => _showReplyDialog(post)),
              _buildActionIcon(
                post.viewerRepost != null ? Icons.repeat_on : Icons.repeat,
                post.repostCount,
                post.viewerRepost != null,
                () => _showRepostMenu(post),
              ),
              _buildActionIcon(
                post.viewerLike != null ? Icons.favorite : Icons.favorite_border,
                post.likeCount,
                post.viewerLike != null,
                () => _handleLike(post),
              ),
              _buildActionIcon(Icons.share_outlined, null, false, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedPost(PostItem quoted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
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
                  ? CircleAvatar(radius: 10, backgroundImage: avatarImageProvider(quoted.avatar))
                  : const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quoted.author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinkifiedText(
            text: quoted.text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          if (quoted.media.isNotEmpty)
            MediaGrid(
              media: quoted.media,
              postLabels: quoted.labels,
              heroTagPrefix: 'quoted-${quoted.uri}',
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, int? count, bool isActive, VoidCallback onTap) {
    Color iconColor = Colors.grey.shade600;
    if (isActive) {
      if (icon == Icons.favorite || icon == Icons.favorite_border) {
        iconColor = Colors.pink;
      } else if (icon == Icons.repeat || icon == Icons.repeat_on) {
        iconColor = Colors.green;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              count > 0 ? count.toString() : '',
              style: TextStyle(color: iconColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime time) {
    final local = time.toLocal();
    return '${local.year}/${local.month}/${local.day} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _handleLike(PostItem post) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (post.viewerLike != null) {
        await _service.delete(post.viewerLike!);
      } else {
        await _service.like(post.id, post.uri);
      }
      _fetchThread();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  void _showRepostMenu(PostItem post) {
    final l10n = AppLocalizations.of(context);
    final isReposted = post.viewerRepost != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isReposted ? Icons.repeat_on : Icons.repeat,
                color: isReposted ? Colors.green : null,
              ),
              title: Text(isReposted ? l10n.repost_undo : l10n.repost),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  if (isReposted) {
                    await _service.delete(post.viewerRepost!);
                  } else {
                    await _service.repost(post.id, post.uri);
                  }
                  _fetchThread();
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                        SnackBar(content: Text(l10n.error_with_message(e.toString()))));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: Text(l10n.timeline_quote_post),
              onTap: () {
                Navigator.pop(context);
                _showQuoteDialog(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewPostScreen(replyTo: post)),
    );
    if (result == true) {
      _fetchThread();
    }
  }

  void _showQuoteDialog(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewPostScreen(quoteOf: post)),
    );
    if (result == true) {
      _fetchThread();
    }
  }
}
