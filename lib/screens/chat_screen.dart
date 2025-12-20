import 'package:flutter/material.dart';

import '../models/post_item.dart';
import '../widgets/message_bubble.dart';
import '../widgets/date_separator.dart';

class ChatScreen extends StatefulWidget {
  final List<PostItem> messages;
  final bool isRefreshing;
  final Function() onRefresh;
  final Function(String text) onSendMessage;

  const ChatScreen({
    super.key,
    required this.messages,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onSendMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
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
    // debugPrint('ChatScreen build: ${widget.messages.length} messages, refreshing: ${widget.isRefreshing}');
    return Scaffold(
      backgroundColor: const Color(0xFF7494C0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
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
    return AppBar(
      backgroundColor: const Color(0xFF7494C0),
      elevation: 1,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bluesky タイムライン', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('オンライン', style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onRefresh,
          icon: widget.isRefreshing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.refresh),
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
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
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
              MessageBubble(message: message, isMe: message.isMe),
            ],
          );
        }

        return MessageBubble(message: message, isMe: message.isMe);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'メッセージを入力',
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
                    ? Colors.grey.shade300
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
