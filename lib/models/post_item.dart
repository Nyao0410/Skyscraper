import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:bluesky/app_bsky_feed_post.dart';

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

      final embed = post.embed;
      if (embed != null) {
        try {
          embed.when(
            imagesView: (data) {
              mediaList.addAll(
                data.images.map(
                  (img) => MediaItem(
                    type: MediaType.image,
                    url: img.fullsize,
                    alt: img.alt,
                  ),
                ),
              );
            },
            videoView: (data) {
              if (data.thumbnail != null) {
                mediaList.add(
                  MediaItem(
                    type: MediaType.video,
                    url: data.thumbnail!,
                    alt: 'Video',
                  ),
                );
              }
            },
            externalView: (data) {
              if (data.external.thumb != null) {
                mediaList.add(
                  MediaItem(
                    type: MediaType.image,
                    url: data.external.thumb!,
                    alt: data.external.title,
                  ),
                );
              }
            },
            recordWithMediaView: (data) {
              data.media.when(
                imagesView: (images) {
                  mediaList.addAll(
                    images.images.map(
                      (img) => MediaItem(
                        type: MediaType.image,
                        url: img.fullsize,
                        alt: img.alt,
                      ),
                    ),
                  );
                },
                videoView: (video) {
                  if (video.thumbnail != null) {
                    mediaList.add(
                      MediaItem(
                        type: MediaType.video,
                        url: video.thumbnail!,
                        alt: 'Video',
                      ),
                    );
                  }
                },
                externalView: (external) {
                  if (external.external.thumb != null) {
                    mediaList.add(
                      MediaItem(
                        type: MediaType.image,
                        url: external.external.thumb!,
                        alt: external.external.title,
                      ),
                    );
                  }
                },
              );
            },
            recordView: (data) {},
            unknown: (data) {},
          );
        } catch (e) {
          // debugPrint('Error parsing embed: ${e.toString()}');
        }
      }

      String postText = '';
      try {
        final dynamic r = record;
        postText = r.text?.toString() ?? '';
      } catch (e) {
        if (record is Map && record.containsKey('text')) {
          postText = record['text'].toString();
        }
      }

      // debugPrint('Parsing post from ${author.handle}, avatar: ${author.avatar ?? "null"}');

      return PostItem(
        id: post.cid,
        author: author.displayName ?? author.handle,
        handle: author.handle,
        avatar: author.avatar,
        text: postText,
        createdAt: post.indexedAt,
        isMe: author.handle == myHandle,
        media: mediaList,
      );
    } catch (e) {
      // debugPrint('Error creating PostItem: ${e.toString()}');
      rethrow;
    }
  }
}
