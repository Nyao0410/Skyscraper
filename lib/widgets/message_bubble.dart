import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_item.dart';

class MessageBubble extends StatelessWidget {
  final PostItem message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

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
                          if (message.text.isNotEmpty) _buildTextBubble(maxBubbleWidth),
                          if (message.media.isNotEmpty)
                            ..._buildMediaWidgets(message.media, maxBubbleWidth),
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
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey.shade300,
      child: hasAvatar
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                memCacheHeight: 120,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildAvatarFallback(),
              ),
            )
          : _buildAvatarFallback(),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Text(
          message.author.isNotEmpty ? message.author[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
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

  Widget _buildTextBubble(double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF8DE055) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
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
        style: TextStyle(
          color: isMe ? Colors.black : Colors.black87,
          fontSize: 15,
        ),
        linkStyle: TextStyle(
          color: isMe ? Colors.blue.shade900 : Colors.blue.shade700,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  List<Widget> _buildMediaWidgets(List<MediaItem> media, double maxWidth) {
    return media.where((item) => item.url.isNotEmpty).map((item) {
      if (item.type == MediaType.image) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 400),
              child: CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
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
        );
      } else if (item.type == MediaType.video) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 200),
              color: Colors.black87,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.url,
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
                  const Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }
}
