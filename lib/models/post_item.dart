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
      // feedView is FeedView
      final dynamic post = feedView.post;
      final dynamic author = post.author;
      final dynamic record = post.record;

      List<MediaItem> mediaList = [];
      PostItem? quoted;

      // Embed parsing using toJson() for robustness against SDK version differences
      if (post.embed != null) {
        try {
          final Map<String, dynamic> embedMap = post.embed.toJson();
          _parseEmbedMap(embedMap, mediaList, (q) => quoted = q, myHandle);
        } catch (e) {
          debugPrint('Error parsing embed: $e');
        }
      }

      String postText = '';
      DateTime? createdAt;

      // Record parsing
      try {
        if (record is Map) {
          postText = record['text']?.toString() ?? '';
          final dynamic ca = record['createdAt'];
          createdAt = ca is DateTime ? ca : DateTime.tryParse(ca?.toString() ?? '');
        } else {
          final dynamic rec = record;
          postText = rec.text?.toString() ?? '';
          final dynamic ca = rec.createdAt;
          createdAt = ca is DateTime ? ca : DateTime.tryParse(ca?.toString() ?? '');
        }
      } catch (e) {
        debugPrint('Error parsing record: $e');
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
        replyCount: post.replyCount ?? 0,
        repostCount: post.repostCount ?? 0,
        likeCount: post.likeCount ?? 0,
      );
    } catch (e) {
      debugPrint('Error in PostItem.fromFeedView: $e');
      rethrow;
    }
  }

  static void _parseEmbedMap(Map<String, dynamic> embedMap, List<MediaItem> mediaList, Function(PostItem) onQuoted, String? myHandle) {
    final String typeStr = embedMap['\$type']?.toString() ?? '';
    
    if (typeStr.contains('app.bsky.embed.images#view')) {
      final List? images = embedMap['images'];
      if (images != null) {
        for (final img in images) {
          mediaList.add(MediaItem(
            type: MediaType.image,
            url: img['fullsize']?.toString() ?? img['thumb']?.toString() ?? '',
            alt: img['alt']?.toString() ?? '',
          ));
        }
      }
    } else if (typeStr.contains('app.bsky.embed.video#view')) {
      mediaList.add(MediaItem(
        type: MediaType.video,
        url: embedMap['thumbnail']?.toString() ?? '',
        alt: 'Video',
      ));
    } else if (typeStr.contains('app.bsky.embed.external#view')) {
      final external = embedMap['external'];
      if (external != null && external['thumb'] != null) {
        mediaList.add(MediaItem(
          type: MediaType.image,
          url: external['thumb'].toString(),
          alt: external['title']?.toString() ?? '',
        ));
      }
    } else if (typeStr.contains('app.bsky.embed.record#view')) {
      final record = embedMap['record'];
      if (record != null && record['\$type']?.toString().contains('app.bsky.embed.record#viewRecord') == true) {
        onQuoted(PostItem.fromRecordMap(record, myHandle));
      }
    } else if (typeStr.contains('app.bsky.embed.recordWithMedia#view')) {
      final record = embedMap['record']?['record'];
      if (record != null && record['\$type']?.toString().contains('app.bsky.embed.record#viewRecord') == true) {
        onQuoted(PostItem.fromRecordMap(record, myHandle));
      }
      final media = embedMap['media'];
      if (media != null) {
        _parseEmbedMap(media, mediaList, (_) {}, myHandle);
      }
    }
  }

  factory PostItem.fromRecordMap(Map<String, dynamic> recordMap, String? myHandle) {
    final author = recordMap['author'] ?? {};
    final value = recordMap['value'] ?? {};
    
    List<MediaItem> mediaList = [];
    final List? embeds = recordMap['embeds'];
    if (embeds != null) {
      for (final embed in embeds) {
        _parseEmbedMap(embed, mediaList, (_) {}, myHandle);
      }
    }

    return PostItem(
      id: recordMap['cid']?.toString() ?? '',
      uri: recordMap['uri']?.toString() ?? '',
      author: (author['displayName'] ?? author['handle'] ?? '').toString(),
      handle: (author['handle'] ?? '').toString(),
      avatar: author['avatar']?.toString(),
      text: value['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(value['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isMe: author['handle'] == myHandle,
      media: mediaList,
    );
  }
}


