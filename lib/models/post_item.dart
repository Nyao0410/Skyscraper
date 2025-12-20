import 'package:flutter/foundation.dart';

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  final String alt;

  MediaItem({required this.type, required this.url, this.alt = ''});
}

class PostItem {
  final String id;
  final String author;
  final String handle;
  final String? avatar;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final List<MediaItem> media;

  PostItem({
    required this.id,
    required this.author,
    required this.handle,
    this.avatar,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.media = const [],
  });

  factory PostItem.fromFeedView(dynamic feedView, String? myHandle) {
    try {
      final post = feedView.post;
      final author = post.author;
      final record = post.record;

      List<MediaItem> mediaList = [];

      // Handle embed
      final embed = post.embed;
      if (embed != null) {
        try {
          embed.whenOrNull(
            images: (data) {
              mediaList = data.images
                  .map(
                    (img) => MediaItem(
                      type: MediaType.image,
                      url: img.fullsize,
                      alt: img.alt,
                    ),
                  )
                  .toList();
            },
            video: (data) {
              final thumbnail = data.thumbnail;
              if (thumbnail != null) {
                mediaList = [
                  MediaItem(type: MediaType.video, url: thumbnail, alt: 'Video'),
                ];
              }
            },
            external: (data) {
              final thumb = data.external.thumb;
              if (thumb != null) {
                mediaList = [
                  MediaItem(
                    type: MediaType.image,
                    url: thumb,
                    alt: data.external.title,
                  ),
                ];
              }
            },
            recordWithMedia: (data) {
              data.media.whenOrNull(
                images: (imgData) {
                  mediaList = imgData.images
                      .map(
                        (img) => MediaItem(
                          type: MediaType.image,
                          url: img.fullsize,
                          alt: img.alt,
                        ),
                      )
                      .toList();
                },
              );
            },
          );
        } catch (e) {
          debugPrint('Error parsing embed: $e');
        }
      }

      // Extract text from record
      String postText = '';
      try {
        if (record is Map) {
          debugPrint('Record is Map. Keys: ${record.keys}');
          postText = record['text']?.toString() ?? '';
        } else {
          postText = record.text.toString();
        }
      } catch (e) {
        debugPrint('Error extracting text from record: $e');
      }

      debugPrint('Extracted text: $postText');

      return PostItem(
        id: post.cid,
        author: author.displayName ?? author.handle,
        handle: author.handle,
        avatar: author.avatar?.toString(),
        text: postText,
        createdAt: post.indexedAt,
        isMe: author.handle == myHandle,
        media: mediaList,
      );
    } catch (e) {
      debugPrint('Critical error in PostItem.fromFeedView: $e');
      rethrow;
    }
  }
}
