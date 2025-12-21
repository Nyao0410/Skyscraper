import 'package:flutter/material.dart';

import '../models/post_item.dart';
import '../widgets/message_bubble.dart';
import '../widgets/date_separator.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final List<PostItem> messages;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Function() onRefresh;
  final Function() onLoadMore;
  final Function(String text) onSendMessage;
  final Function(PostItem item)? onLike;
  final Function(PostItem item)? onUnlike;
  final Function(PostItem item)? onRepost;
  final Function(PostItem item)? onUnrepost;
  final Function(PostItem item)? onReply;
  final Function(PostItem item)? onQuote;
  final Function(PostItem item)? onDelete;

  const ChatScreen({
    super.key,
    this.title = 'Bluesky タイムライン',
    required this.messages,
    required this.isRefreshing,
    this.isLoadingMore = false,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onSendMessage,
    this.onLike,
    this.onUnlike,
    this.onRepost,
    this.onUnrepost,
    this.onReply,
    this.onQuote,
    this.onDelete,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新しいメッセージが追加された場合（リストの先頭が変わった場合）のみスクロール
    if (widget.messages.isNotEmpty && oldWidget.messages.isNotEmpty) {
      if (widget.messages.first.id != oldWidget.messages.first.id) {
        _scrollToBottom();
      }
    } else if (widget.messages.length > oldWidget.messages.length && oldWidget.messages.isEmpty) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // debugPrint('ChatScreen build: ${widget.messages.length} messages, refreshing: ${widget.isRefreshing}');
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1D21) : const Color(0xFF7494C0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: widget.messages.isEmpty && !widget.isRefreshing
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF7494C0);
    final textColor = Colors.white;

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 1,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          Text('オンライン', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7))),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onRefresh,
          icon: widget.isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
                )
              : Icon(Icons.refresh, color: textColor),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isRefreshing ? Icons.sync : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isRefreshing ? '読み込み中...' : '投稿がありません',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: widget.messages.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        final message = widget.messages[index];
        
        // 日付の区切りを表示するか判定
        bool showDateSeparator = false;
        if (index == widget.messages.length - 1) {
          // 一番古いメッセージには必ず日付を表示
          showDateSeparator = true;
        } else {
          // 一つ古いメッセージと日付が異なる場合に表示
          final nextMessage = widget.messages[index + 1];
          if (message.createdAt.year != nextMessage.createdAt.year ||
              message.createdAt.month != nextMessage.createdAt.month ||
              message.createdAt.day != nextMessage.createdAt.day) {
            showDateSeparator = true;
          }
        }

        if (showDateSeparator) {
          return Column(
            children: [
              DateSeparator(date: message.createdAt),
              MessageBubble(
                message: message,
                isMe: message.isMe,
                onLike: widget.onLike,
                onUnlike: widget.onUnlike,
                onRepost: widget.onRepost,
                onUnrepost: widget.onUnrepost,
                onReply: widget.onReply,
                onQuote: widget.onQuote,
                onDelete: widget.onDelete,
              ),
            ],
          );
        }

        return MessageBubble(
          message: message,
          isMe: message.isMe,
          onLike: widget.onLike,
          onUnlike: widget.onUnlike,
          onRepost: widget.onRepost,
          onUnrepost: widget.onUnrepost,
          onReply: widget.onReply,
          onQuote: widget.onQuote,
          onDelete: widget.onDelete,
        );
      },
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  minLines: 1,
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'メッセージを入力',
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _handleSend,
              icon: Icon(
                Icons.send,
                color: _textController.text.trim().isEmpty
                    ? Colors.grey.shade400
                    : const Color(0xFF00C300),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
