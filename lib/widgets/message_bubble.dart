import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
// url_launcher not used here; remove unused import

import '../models/post_item.dart';
import '../screens/thread_screen.dart';
import '../screens/profile_screen.dart';
import 'linkified_text.dart';
import 'media_viewer.dart';
import 'video_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final PostItem message;
  final bool isMe;
  final Function(PostItem)? onLike;
  final Function(PostItem)? onUnlike;
  final Function(PostItem)? onRepost;
  final Function(PostItem)? onUnrepost;
  final Function(PostItem)? onReply;
  final Function(PostItem)? onQuote;
  final Function(PostItem)? onDelete;
  final void Function(String tag)? onInsertText;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLike,
    this.onUnlike,
    this.onRepost,
    this.onUnrepost,
    this.onReply,
    this.onQuote,
    this.onDelete,
    this.onInsertText,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.75;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(context),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThreadScreen(postUri: message.uri),
                  ),
                );
              },
              onLongPress: () => _showMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    _buildAuthorName(context),
                    const SizedBox(height: 4),
                  ],
                  if (message.repostedBy != null) ...[
                    _buildRepostIndicator(context),
                    const SizedBox(height: 4),
                  ],
                  if (message.replyParentPost != null) ...[
                    _buildReplyPost(maxBubbleWidth, context),
                    const SizedBox(height: 1),
                  ] else if (message.replyParentHandle != null) ...[
                    _buildReplyIndicator(context),
                    const SizedBox(height: 2),
                  ],
                  if (message.text.isNotEmpty || message.quotedPost != null)
                    Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isMe) _buildTimestamp(context),
                        const SizedBox(width: 4),
                        Flexible(
                          child: _buildMainBubble(maxBubbleWidth, context),
                        ),
                        const SizedBox(width: 4),
                        if (!isMe) _buildTimestamp(context),
                      ],
                    ),
                  if (message.media.isNotEmpty) ...[
                    if (message.text.isNotEmpty || message.quotedPost != null)
                      const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isMe) _buildTimestamp(context),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: _buildMediaWidgets(message.media, maxBubbleWidth, context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (!isMe) _buildTimestamp(context),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final handle = message.replyParentHandle;
    final displayHandle = (handle != null && !handle.startsWith('@')) ? '@$handle' : handle;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reply, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            l10n.reply_to(displayHandle ?? ''),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRepostIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rep = message.repostedBy ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 14, color: Colors.greenAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              rep.isNotEmpty ? l10n.reposted_by(rep) : l10n.repost,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPost(double maxWidth, BuildContext context) {
    final parent = message.replyParentPost!;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${parent.author} (@${parent.handle})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            parent.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMainBubble(double maxWidth, BuildContext context) {
    final hasReplyParent = message.replyParentPost != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: isMe 
            ? const Color(0xFF8DE055) 
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(hasReplyParent ? 0 : 16),
          topRight: Radius.circular(hasReplyParent ? 0 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: LinkifiedText(
                text: message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isMe ? Colors.black : (isDark ? Colors.white : Colors.black87),
                ),
                linkStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isMe ? Colors.blue.shade900 : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                  decoration: TextDecoration.underline,
                ),
                onHashtagLongPress: (tag) => onInsertText?.call(tag),
              ),
            ),
          if (message.quotedPost != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _buildQuotedPostInside(maxWidth - 16, context),
            ),
        ],
      ),
    );
  }

  Widget _buildQuotedPostInside(double maxWidth, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quoted = message.quotedPost!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe 
            ? (quoted.isMe ? const Color(0xFF6FB83A) : const Color(0xFF7BC946))
            : (isDark ? Colors.black26 : (quoted.isMe ? Colors.grey.shade100 : Colors.grey.shade200)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12, 
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (quoted.avatar != null)
                CircleAvatar(
                  radius: 8,
                  backgroundImage: avatarImageProvider(quoted.avatar),
                )
              else
                const Icon(Icons.account_circle, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  quoted.isMe ? l10n.me : quoted.author,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: quoted.isMe ? (isMe ? Colors.white : Colors.blue) : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinkifiedText(
            text: quoted.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black87),
            onHashtagLongPress: (tag) => onInsertText?.call(tag),
          ),
          if (quoted.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: quoted.media.take(2).map((m) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(m.url),
                      fit: BoxFit.cover,
                    ),
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final localTime = message.createdAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = message.avatar;
    final provider = avatarImageProvider(avatarUrl);
    final isValidUrl = provider != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(actor: message.handle)),
        );
      },
      child: Container(
        width: 35, // 少し大きく
        height: 35, // 少し大きく
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: isValidUrl
            ? Transform.scale(
                scale: 1.2, // 内部の画像を20%拡大
                child: Image(
                  image: provider,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  Widget _buildAuthorName(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message.author,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLiked = message.viewerLike != null;
    final isReposted = message.viewerRepost != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pink,
                ),
                title: Text(isLiked ? l10n.unlike : l10n.like),
                onTap: () {
                  Navigator.pop(context);
                  if (isLiked) {
                    onUnlike?.call(message);
                  } else {
                    onLike?.call(message);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  isReposted ? Icons.repeat_on : Icons.repeat,
                  color: Colors.green,
                ),
                title: Text(isReposted ? l10n.unrepost : l10n.repost),
                onTap: () {
                  Navigator.pop(context);
                  if (isReposted) {
                    onUnrepost?.call(message);
                  } else {
                    onRepost?.call(message);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_quote, color: Colors.blue),
                title: Text(l10n.quote),
                onTap: () {
                  Navigator.pop(context);
                  onQuote?.call(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.grey),
                title: Text(l10n.reply),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(l10n.delete_local, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMediaWidgets(List<MediaItem> media, double maxWidth, BuildContext context) {
    if (media.isEmpty) return [];

    // 複数画像がある場合はグリッド表示を検討できるが、まずはシンプルに縦並び
    return media.asMap().entries.where((e) => e.value.url.isNotEmpty).map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
        child: _buildSingleMedia(item, maxWidth, context),
      );
    }).toList();
  }

  Widget _buildSingleMedia(MediaItem item, double maxWidth, BuildContext context) {
    if (item.type == MediaType.image) {
      return GestureDetector(
        onLongPress: () => _showMenu(context),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MediaViewer(media: [item], initialIndex: 0),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: 300,
            ),
            child: Hero(
              tag: item.url,
              child: CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 800,
                placeholder: (context, url) => Container(
                  height: 150,
                  width: maxWidth,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  padding: const EdgeInsets.all(20),
                  width: maxWidth,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (item.type == MediaType.video && item.videoUrl != null) {
      return GestureDetector(
        onLongPress: () => _showMenu(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: VideoPlayerWidget(url: item.videoUrl!),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
