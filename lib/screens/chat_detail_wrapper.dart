import 'package:flutter/material.dart';
import '../services/bluesky_service.dart';
import '../models/post_item.dart';
import 'chat_screen.dart';
import 'new_post_screen.dart';

class ChatDetailWrapper extends StatefulWidget {
  final String feedName;
  final String feedUri;

  const ChatDetailWrapper({super.key, required this.feedName, required this.feedUri});

  @override
  State<ChatDetailWrapper> createState() => _ChatDetailWrapperState();
}

class _ChatDetailWrapperState extends State<ChatDetailWrapper> {
  final _service = BlueskyService();
  List<PostItem> _feed = [];
  String? _cursor;
  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final cachedPosts = await _service.getCachedCustomFeed(widget.feedUri);
      if (cachedPosts.isNotEmpty && mounted) {
        setState(() {
          _feed = cachedPosts;
          _loading = false;
        });
        _markAsSeen();
      }
    } catch (e) {
      debugPrint('Error loading cached feed: $e');
    }

    try {
      final response = await _service.getCustomFeed(widget.feedUri);
      if (mounted) {
        setState(() {
          _feed = response.posts;
          _cursor = response.cursor;
          _loading = false;
        });
        _markAsSeen();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (_feed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('フィードの取得に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAsSeen() async {
    if (_feed.isNotEmpty) {
      final latest = _feed.first;
      await _service.updateLastSeen(widget.feedUri, latest.id, latest.createdAt);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      final response = await _service.getCustomFeed(widget.feedUri);
      setState(() {
        _feed = response.posts;
        _cursor = response.cursor;
        _refreshing = false;
      });
      _markAsSeen();
    } catch (e) {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _handleLoadMore() async {
    if (_loadingMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _service.getCustomFeed(widget.feedUri, cursor: _cursor);
      if (mounted) {
        setState(() {
          _feed.addAll(response.posts);
          _cursor = response.cursor;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    try {
      await _service.post(text);
      _handleRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChatScreen(
      title: widget.feedName,
      messages: _feed,
      isRefreshing: _refreshing,
      isLoadingMore: _loadingMore,
      onRefresh: _handleRefresh,
      onLoadMore: _handleLoadMore,
      onSendMessage: _handleSendMessage,
      onLike: (item) async {
        await _service.like(item.id, item.uri);
        _handleRefresh();
      },
      onUnlike: (item) async {
        if (item.viewerLike != null) {
          await _service.delete(item.viewerLike!);
          _handleRefresh();
        }
      },
      onRepost: (item) async {
        await _service.repost(item.id, item.uri);
        _handleRefresh();
      },
      onUnrepost: (item) async {
        if (item.viewerRepost != null) {
          await _service.delete(item.viewerRepost!);
          _handleRefresh();
        }
      },
      onDelete: (item) async {
        await _service.delete(item.uri, cid: item.id);
        _handleRefresh();
      },
      onReply: (item) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPostScreen(replyTo: item)),
        );
        if (result == true) _handleRefresh();
      },
      onQuote: (item) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPostScreen(quoteOf: item)),
        );
        if (result == true) _handleRefresh();
      },
    );
  }
}
