import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../models/post_item.dart';
import '../services/bluesky_service.dart';
import '../utils/avatar_provider.dart';
import 'linkified_text.dart';
import 'media_grid.dart';
import '../screens/profile_screen.dart';
import '../screens/thread_screen.dart';
import '../screens/new_post_screen.dart';

class PostWidget extends StatefulWidget {
  final PostItem post;
  final VoidCallback? onPostUpdated;
  final bool showThreadOnTap;
  final double leftPadding;

  const PostWidget({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.showThreadOnTap = true,
    this.leftPadding = 12.0,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final _service = BlueskyService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = widget.post;

    return InkWell(
      onTap: widget.showThreadOnTap
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThreadScreen(postUri: post.uri)),
              );
            }
          : null,
      child: Padding(
        padding: EdgeInsets.only(left: widget.leftPadding, top: 12, right: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.repostedBy != null)
              Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
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
                    backgroundImage: avatarImageProvider(post.avatar),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
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
                        selectable: true,
                        onHashtagLongPress: (tag) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewPostScreen(initialText: '$tag '),
                            ),
                          );
                        },
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionIcon(Icons.chat_bubble_outline, post.replyCount, false, () => _showReplyDialog(post)),
                          _buildActionIcon(
                            post.viewerRepost != null ? Icons.repeat_on : Icons.repeat,
                            post.repostCount,
                            post.viewerRepost != null,
                            () => _handleRepost(post),
                          ),
                          _buildActionIcon(
                            post.viewerLike != null ? Icons.favorite : Icons.favorite_border,
                            post.likeCount,
                            post.viewerLike != null,
                            () => _handleLike(post),
                          ),
                          _buildActionIcon(Icons.more_horiz, null, false, () => _showPostMenu(post)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedPost(PostItem quoted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThreadScreen(postUri: quoted.uri),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                              backgroundImage: avatarImageProvider(quoted.avatar),
                            )
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
                  selectable: true,
                  onHashtagLongPress: (tag) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewPostScreen(initialText: '$tag '),
                      ),
                    );
                  },
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
          ),
        ),
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

  String _formatTime(DateTime time) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());
    if (diff.inMinutes < 1) return l10n.now;
    if (diff.inHours < 1) return '${diff.inMinutes}${l10n.minutes}';
    if (diff.inDays < 1) return '${diff.inHours}${l10n.hours}';
    return '${time.month}/${time.day}';
  }

  void _handleLike(PostItem post) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (post.viewerLike != null) {
        await _service.delete(post.viewerLike!);
      } else {
        await _service.like(post.id, post.uri);
      }
      widget.onPostUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  void _handleRepost(PostItem post) async {
    final l10n = AppLocalizations.of(context);
    
    // If already reposted, just undo it
    if (post.viewerRepost != null) {
      try {
        await _service.delete(post.viewerRepost!);
        widget.onPostUpdated?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error_with_message(e.toString())))
          );
        }
      }
      return;
    }

    // Show menu to choose between Repost and Quote
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.green),
              title: Text(l10n.repost),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _service.repost(post.id, post.uri);
                  widget.onPostUpdated?.call();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.error_with_message(e.toString())))
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote, color: Colors.blue),
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

  void _showPostMenu(PostItem post) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: Text(l10n.timeline_quote_post),
              onTap: () {
                Navigator.pop(context);
                _showQuoteDialog(post);
              },
            ),
            if (post.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _service.delete(post.uri, cid: post.id);
                  widget.onPostUpdated?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copyText),
              onTap: () {
                Navigator.pop(context);
                try {
                  Clipboard.setData(ClipboardData(text: post.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.copyText} ✓')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.error_with_message(e.toString()))),
                  );
                }
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
      widget.onPostUpdated?.call();
    }
  }

  void _showQuoteDialog(PostItem post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewPostScreen(quoteOf: post)),
    );
    if (result == true) {
      widget.onPostUpdated?.call();
    }
  }
}
