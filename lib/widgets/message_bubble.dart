import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_item.dart';

class MessageBubble extends StatelessWidget {
  final PostItem message;
  final bool isMe;
  final Function(PostItem)? onLike;
  final Function(PostItem)? onRepost;
  final Function(PostItem)? onReply;
  final Function(PostItem)? onQuote;
  final Function(PostItem)? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLike,
    this.onRepost,
    this.onReply,
    this.onQuote,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.75;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    _buildAuthorName(),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isMe) _buildTimestamp(),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (message.text.isNotEmpty) _buildTextBubble(maxBubbleWidth, context),
                            if (message.media.isNotEmpty)
                              ..._buildMediaWidgets(message.media, maxBubbleWidth, context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!isMe) _buildTimestamp(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = message.avatar;
    final isValidUrl = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return Container(
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
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                memCacheWidth: 132,
                memCacheHeight: 132,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return const Icon(Icons.person, color: Colors.white);
                },
              ),
            )
          : const Icon(Icons.person, color: Colors.white),
    );
  }

  Widget _buildAuthorName() {
    return Text(
      message.author,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  void _showMenu(BuildContext context) {
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
                leading: const Icon(Icons.favorite_border, color: Colors.pink),
                title: const Text('いいね'),
                onTap: () {
                  Navigator.pop(context);
                  onLike?.call(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat, color: Colors.green),
                title: const Text('RP'),
                onTap: () {
                  Navigator.pop(context);
                  onRepost?.call(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_quote, color: Colors.blue),
                title: const Text('引用'),
                onTap: () {
                  Navigator.pop(context);
                  onQuote?.call(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.grey),
                title: const Text('返信'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('削除(自分のみ)', style: TextStyle(color: Colors.red)),
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

  Widget _buildTextBubble(double maxWidth, BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF8DE055) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 16 : 4),
            topRight: const Radius.circular(16),
            bottomLeft: const Radius.circular(16),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Linkify(
          onOpen: (link) async {
            final uri = Uri.parse(link.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          text: message.text,
          softWrap: true, // テキストを折り返して全文表示
          style: TextStyle(
            color: isMe ? Colors.black : Colors.black87,
            fontSize: 15,
          ),
          linkStyle: TextStyle(
            color: isMe ? Colors.blue.shade900 : Colors.blue.shade700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMediaWidgets(List<MediaItem> media, double maxWidth, BuildContext context) {
    if (media.isEmpty) return [];

    // 複数画像がある場合はグリッド表示を検討できるが、まずはシンプルに縦並び
    return media.where((item) => item.url.isNotEmpty).map((item) {
      if (item.type == MediaType.image) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            onLongPress: () => _showMenu(context),
            onTap: () {
              // TODO: 画像拡大表示
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: 300, // LINE風に少し高さを抑える
                ),
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
      } else if (item.type == MediaType.video) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            onLongPress: () => _showMenu(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: 200,
                ),
                color: Colors.black87,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.url, // 動画の場合はサムネイルURL
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.video_library,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                    // 再生ボタンアイコン
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.play_arrow, size: 32, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }
}
