import 'package:flutter/foundation.dart';

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  final String alt;

  MediaItem({required this.type, required this.url, this.alt = ''});
}

class PostItem {
  final String id; // CID
  final String uri; // AtUri
  final String author;
  final String handle;
  final String? avatar;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final List<MediaItem> media;
  final PostItem? quotedPost;
  final int replyCount;
  final int repostCount;
  final int likeCount;

  PostItem({
    required this.id,
    required this.uri,
    required this.author,
    required this.handle,
    this.avatar,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.media = const [],
    this.quotedPost,
    this.replyCount = 0,
    this.repostCount = 0,
    this.likeCount = 0,
  });

  factory PostItem.fromFeedView(dynamic feedView, String? myHandle) {
    try {
      final post = feedView.post;
      final author = post.author;
      final record = post.record;

      List<MediaItem> mediaList = [];
      PostItem? quoted;

      final embed = post.embed;
      if (embed != null) {
        try {
          embed.when(
            embedImagesView: (data) {
              try {
                final images = data.images;
                for (final img in images) {
                  mediaList.add(MediaItem(
                    type: MediaType.image,
                    url: img.fullsize.toString(),
                    alt: img.alt.toString(),
                  ));
                }
              } catch (_) {}
            },
            embedVideoView: (data) {
              try {
                final thumb = data.thumbnail;
                if (thumb != null) {
                  mediaList.add(MediaItem(
                    type: MediaType.video,
                    url: thumb.toString(),
                    alt: 'Video',
                  ));
                }
              } catch (_) {}
            },
            embedExternalView: (data) {
              try {
                final thumb = data.external.thumb;
                if (thumb != null) {
                  mediaList.add(MediaItem(
                    type: MediaType.image,
                    url: thumb.toString(),
                    alt: data.external.title.toString(),
                  ));
                }
              } catch (_) {}
            },
            embedRecordView: (data) {
              try {
                data.record.when(
                  embedRecordViewRecord: (record) {
                    quoted = PostItem.fromRecordView(record, myHandle);
                  },
                  unknown: (data) {},
                );
              } catch (_) {}
            },
            embedRecordWithMediaView: (data) {
              try {
                data.record.when(
                  embedRecordViewRecord: (record) {
                    quoted = PostItem.fromRecordView(record, myHandle);
                  },
                  unknown: (data) {},
                );

                data.media.when(
                  embedImagesView: (imagesData) {
                    for (final img in imagesData.images) {
                      mediaList.add(MediaItem(
                        type: MediaType.image,
                        url: img.fullsize.toString(),
                        alt: img.alt.toString(),
                      ));
                    }
                  },
                  embedVideoView: (videoData) {
                    final thumb = videoData.thumbnail;
                    if (thumb != null) {
                      mediaList.add(MediaItem(
                        type: MediaType.video,
                        url: thumb.toString(),
                        alt: 'Video',
                      ));
                    }
                  },
                  embedExternalView: (externalData) {
                    final thumb = externalData.external.thumb;
                    if (thumb != null) {
                      mediaList.add(MediaItem(
                        type: MediaType.image,
                        url: thumb.toString(),
                        alt: externalData.external.title.toString(),
                      ));
                    }
                  },
                  unknown: (data) {},
                );
              } catch (_) {}
            },
            unknown: (data) {},
          );
        } catch (e) {
          debugPrint('Error parsing embed: $e');
        }
      }

      String postText = '';
      DateTime? createdAt;

      debugPrint('Parsing record in fromFeedView, type: ${record.runtimeType}');
      try {
        if (record != null) {
          final dynamic rec = record;
          postText = rec.text?.toString() ?? '';
          createdAt = rec.createdAt is DateTime ? rec.createdAt : DateTime.tryParse(rec.createdAt.toString());
        }
      } catch (e) {
        debugPrint('Error accessing record fields dynamically: $e');
        if (record is Map) {
          postText = record['text']?.toString() ?? '';
          createdAt = DateTime.tryParse(record['createdAt']?.toString() ?? '');
        }
      }

      return PostItem(
        id: post.cid.toString(),
        uri: post.uri.toString(),
        author: (author.displayName ?? author.handle).toString(),
        handle: author.handle.toString(),
        avatar: author.avatar?.toString(),
        text: postText,
        createdAt: createdAt ?? post.indexedAt,
        isMe: author.handle.toString() == myHandle,
        media: mediaList,
        quotedPost: quoted,
        replyCount: post.replyCount,
        repostCount: post.repostCount,
        likeCount: post.likeCount,
      );
    } catch (e) {
      debugPrint('Error in PostItem.fromFeedView: $e');
      rethrow;
    }
  }

  factory PostItem.fromRecordView(dynamic recordView, String? myHandle) {
    try {
      final author = recordView.author;
      final record = recordView.value;

      List<MediaItem> mediaList = [];
      final embeds = recordView.embeds;
      if (embeds != null && embeds is List) {
        for (final embed in embeds) {
          embed.when(
            embedImagesView: (data) {
              final images = data.images;
              if (images is List) {
                mediaList.addAll(
                  images.map(
                    (img) => MediaItem(
                      type: MediaType.image,
                      url: img.fullsize.toString(),
                      alt: img.alt.toString(),
                    ),
                  ),
                );
              }
            },
            embedVideoView: (data) {
              try {
                final thumb = data.thumbnail;
                if (thumb != null) {
                  mediaList.add(
                    MediaItem(
                      type: MediaType.video,
                      url: thumb.toString(),
                      alt: 'Video',
                    ),
                  );
                }
              } catch (_) {}
            },
            embedExternalView: (data) {
              try {
                final thumb = data.external.thumb;
                if (thumb != null) {
                  mediaList.add(
                    MediaItem(
                      type: MediaType.image,
                      url: thumb.toString(),
                      alt: data.external.title.toString(),
                    ),
                  );
                }
              } catch (_) {}
            },
            embedRecordView: (data) {
              // Nested quotes are usually not fully expanded or handled differently
            },
            embedRecordWithMediaView: (data) {
              try {
                data.media.when(
                  embedImagesView: (imagesData) {
                    final images = imagesData.images;
                    if (images is List) {
                      for (final img in images) {
                        mediaList.add(MediaItem(
                          type: MediaType.image,
                          url: img.fullsize.toString(),
                          alt: img.alt.toString(),
                        ));
                      }
                    }
                  },
                  embedVideoView: (videoData) {
                    final thumb = videoData.thumbnail;
                    if (thumb != null) {
                      mediaList.add(
                        MediaItem(
                          type: MediaType.video,
                          url: thumb.toString(),
                          alt: 'Video',
                        ),
                      );
                    }
                  },
                  embedExternalView: (externalData) {
                    final thumb = externalData.external.thumb;
                    if (thumb != null) {
                      mediaList.add(
                        MediaItem(
                          type: MediaType.image,
                          url: thumb.toString(),
                          alt: externalData.external.title.toString(),
                        ),
                      );
                    }
                  },
                  unknown: (data) {},
                );
              } catch (_) {}
            },
            unknown: (data) {},
          );
        }
      }

      String postText = '';
      DateTime? createdAt;

      debugPrint('Parsing record in fromRecordView, type: ${record.runtimeType}');
      try {
        if (record != null) {
          final dynamic rec = record;
          postText = rec.text?.toString() ?? '';
          createdAt = rec.createdAt is DateTime ? rec.createdAt : DateTime.tryParse(rec.createdAt.toString());
        }
      } catch (e) {
        debugPrint('Error accessing record fields dynamically in fromRecordView: $e');
        if (record is Map) {
          postText = record['text']?.toString() ?? '';
          createdAt = DateTime.tryParse(record['createdAt']?.toString() ?? '');
        }
      }

      return PostItem(
        id: recordView.cid.toString(),
        uri: recordView.uri.toString(),
        author: (author.displayName ?? author.handle).toString(),
        handle: author.handle.toString(),
        avatar: author.avatar?.toString(),
        text: postText,
        createdAt: createdAt ?? recordView.indexedAt,
        isMe: author.handle.toString() == myHandle,
        media: mediaList,
      );
    } catch (e) {
      debugPrint('Error in PostItem.fromRecordView: $e');
      rethrow;
    }
  }
}
