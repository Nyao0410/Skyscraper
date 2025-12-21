import 'package:flutter/foundation.dart';

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  final String alt;

  MediaItem({required this.type, required this.url, this.alt = ''});

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'url': url,
        'alt': alt,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        type: MediaType.values[json['type'] as int],
        url: json['url'] as String,
        alt: json['alt'] as String? ?? '',
      );
}

class StrongRef {
  final String cid;
  final String uri;
  StrongRef({required this.cid, required this.uri});

  Map<String, dynamic> toJson() => {
        'cid': cid,
        'uri': uri,
      };

  factory StrongRef.fromJson(Map<String, dynamic> json) => StrongRef(
        cid: json['cid'] as String,
        uri: json['uri'] as String,
      );
}

class FeedResponse {
  final List<PostItem> posts;
  final String? cursor;
  FeedResponse({required this.posts, this.cursor});
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
  final StrongRef? replyRoot;
  final StrongRef? replyParent;
  final String? replyParentHandle;
  final PostItem? replyParentPost;
  final String? repostedBy; // Display name of the person who reposted
  final String? viewerLike; // URI of the like record if liked
  final String? viewerRepost; // URI of the repost record if reposted

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
    this.replyRoot,
    this.replyParent,
    this.replyParentHandle,
    this.replyParentPost,
    this.repostedBy,
    this.viewerLike,
    this.viewerRepost,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uri': uri,
        'author': author,
        'handle': handle,
        'avatar': avatar,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isMe': isMe ? 1 : 0,
        'media': media.map((m) => m.toJson()).toList(),
        'quotedPost': quotedPost?.toJson(),
        'replyCount': replyCount,
        'repostCount': repostCount,
        'likeCount': likeCount,
        'replyRoot': replyRoot?.toJson(),
        'replyParent': replyParent?.toJson(),
        'replyParentHandle': replyParentHandle,
        'replyParentPost': replyParentPost?.toJson(),
        'repostedBy': repostedBy,
        'viewerLike': viewerLike,
        'viewerRepost': viewerRepost,
      };

  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id'] as String,
      uri: json['uri'] as String,
      author: json['author'] as String,
      handle: json['handle'] as String,
      avatar: json['avatar'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMe: (json['isMe'] as int) == 1,
      media: (json['media'] as List?)
              ?.map((m) => MediaItem.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      quotedPost: json['quotedPost'] != null
          ? PostItem.fromJson(json['quotedPost'] as Map<String, dynamic>)
          : null,
      replyCount: json['replyCount'] as int? ?? 0,
      repostCount: json['repostCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      replyRoot: json['replyRoot'] != null
          ? StrongRef.fromJson(json['replyRoot'] as Map<String, dynamic>)
          : null,
      replyParent: json['replyParent'] != null
          ? StrongRef.fromJson(json['replyParent'] as Map<String, dynamic>)
          : null,
      replyParentHandle: json['replyParentHandle'] as String?,
      replyParentPost: json['replyParentPost'] != null
          ? PostItem.fromJson(json['replyParentPost'] as Map<String, dynamic>)
          : null,
      repostedBy: json['repostedBy'] as String?,
      viewerLike: json['viewerLike'] as String?,
      viewerRepost: json['viewerRepost'] as String?,
    );
  }

  factory PostItem.fromFeedView(dynamic feedView, String? myHandle) {
    try {
      // Convert to Map for safe access
      Map<String, dynamic> data;
      if (feedView is Map) {
        data = Map<String, dynamic>.from(feedView);
      } else {
        try {
          data = feedView.toJson();
        } catch (e) {
          debugPrint('toJson failed in fromFeedView: $e');
          // Fallback: if it's already a post-like object
          return PostItem(
            id: '',
            uri: '',
            author: 'Unknown',
            handle: 'unknown',
            text: '解析エラー',
            createdAt: DateTime.now(),
            isMe: false,
          );
        }
      }

      // Handle Union wrapper if present (some SDK versions wrap data in a 'data' field)
      Map<String, dynamic> postData;
      if (data.containsKey('post')) {
        postData = data['post'];
      } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('post')) {
        postData = data['data']['post'];
      } else {
        // If the map itself looks like a post
        postData = data;
      }

      final author = postData['author'] ?? {};
      final record = postData['record'] ?? {};
      final reply = data['reply'] ?? postData['reply'];
      final reason = data['reason'];
      final viewer = postData['viewer'] ?? {};

      String? repostedBy;
      if (reason != null && reason is Map) {
        final dynamic typeStr = reason['\$type'] ?? reason[r'$type'];
        if (typeStr != null && typeStr.toString().contains('reasonRepost')) {
          final by = reason['by'];
          if (by != null && by is Map) {
            repostedBy = (by['displayName'] ?? by['handle'] ?? '').toString();
          }
        }
      }

      String? viewerLike;
      String? viewerRepost;
      if (viewer is Map) {
        viewerLike = viewer['like']?.toString();
        viewerRepost = viewer['repost']?.toString();
      }

      List<MediaItem> mediaList = [];
      PostItem? quoted;

      // Embed parsing
      if (postData['embed'] != null) {
        try {
          final embed = postData['embed'];
          final Map<String, dynamic> embedMap = (embed is Map) ? Map<String, dynamic>.from(embed) : embed.toJson();
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
          createdAt = DateTime.tryParse(ca?.toString() ?? '');
        }
      } catch (e) {
        debugPrint('Error parsing record: $e');
      }

      // Reply parsing
      StrongRef? root;
      StrongRef? parent;
      String? parentHandle;
      PostItem? parentPost;
      if (reply != null && reply is Map) {
        if (reply['root'] != null) {
          root = StrongRef(
            cid: reply['root']['cid']?.toString() ?? '',
            uri: reply['root']['uri']?.toString() ?? '',
          );
        }
        if (reply['parent'] != null) {
          final parentData = reply['parent'];
          parent = StrongRef(
            cid: parentData['cid']?.toString() ?? '',
            uri: parentData['uri']?.toString() ?? '',
          );
          // Extract parent handle if available
          final parentAuthor = parentData['author'];
          if (parentAuthor != null && parentAuthor is Map) {
            parentHandle = parentAuthor['handle']?.toString();
          }
          // Try to parse parent as a PostItem if it looks like a post view
          if (parentData.containsKey('record')) {
            try {
              parentPost = PostItem.fromFeedView(parentData, myHandle);
            } catch (e) {
              debugPrint('Failed to parse parent post: $e');
            }
          }
        }
      }

      return PostItem(
        id: postData['cid']?.toString() ?? '',
        uri: postData['uri']?.toString() ?? '',
        author: (author['displayName'] ?? author['handle'] ?? 'Unknown').toString(),
        handle: (author['handle'] ?? 'unknown').toString(),
        avatar: author['avatar']?.toString(),
        text: postText,
        createdAt: createdAt ?? (postData['indexedAt'] != null ? DateTime.tryParse(postData['indexedAt'].toString()) : null) ?? DateTime.now(),
        isMe: author['handle']?.toString() == myHandle,
        media: mediaList,
        quotedPost: quoted,
        replyCount: postData['replyCount'] ?? 0,
        repostCount: postData['repostCount'] ?? 0,
        likeCount: postData['likeCount'] ?? 0,
        replyRoot: root,
        replyParent: parent,
        replyParentHandle: parentHandle,
        replyParentPost: parentPost,
        repostedBy: repostedBy,
        viewerLike: viewerLike,
        viewerRepost: viewerRepost,
      );
    } catch (e) {
      debugPrint('Critical error in PostItem.fromFeedView: $e');
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


