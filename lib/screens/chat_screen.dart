import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../flutter_gen/gen_l10n/app_localizations.dart';

import '../models/post_item.dart';
import '../widgets/message_bubble.dart';
import '../widgets/date_separator.dart';
import 'new_post_screen.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final List<PostItem> messages;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Function() onRefresh;
  final Function() onLoadMore;
  final Function(String text, {List<XFile>? images}) onSendMessage;
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
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final int _maxChars = 300;
  bool _canSend = false;
  int _remaining = 300;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _onTextChanged();
  }

  void _onTextChanged() {
    final len = _textController.text.length;
    final remaining = (_maxChars - len).clamp(0, _maxChars);
    final canSend = (_textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty) && len <= _maxChars;
    if (remaining != _remaining || canSend != _canSend) {
      setState(() {
        _remaining = remaining;
        _canSend = canSend;
      });
    }
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.new_post_max_images))
      );
      return;
    }
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 4) {
          _selectedImages.removeRange(4, _selectedImages.length);
        }
      });
      _onTextChanged();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.removeListener(_onTextChanged);
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
    if (text.isEmpty && _selectedImages.isEmpty) return;
    widget.onSendMessage(text, images: _selectedImages.isEmpty ? null : List.from(_selectedImages));
    _textController.clear();
    setState(() {
      _selectedImages.clear();
    });
    _onTextChanged();
  }

  void _insertTagToComposer(String tag) {
    final normalized = tag.startsWith('#') ? tag : '#$tag';
    final current = _textController.text;
    final needsSpace = current.isNotEmpty && !current.endsWith(' ');
    final newText = current + (needsSpace ? ' ' : '') + normalized;
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // debugPrint('ChatScreen build: ${widget.messages.length} messages, refreshing: ${widget.isRefreshing}');
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1D21) : const Color(0xFF7494C0),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
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
            ),
            _buildInputArea(),
          ],
        ),
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
    final l10n = AppLocalizations.of(context);
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
            widget.isRefreshing ? l10n.loading : l10n.timeline_no_posts,
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
                onInsertText: _insertTagToComposer,
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
          onInsertText: _insertTagToComposer,
        );
      },
    );
  }

  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedImages.removeAt(index));
                                _onTextChanged();
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _pickImages,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TextField(
                      controller: _textController,
                      // Limit input to 10 lines to avoid unlimited growth
                      maxLines: 10,
                      minLines: 1,
                      // Slightly smaller font for input text
                      style: TextStyle(color: textColor, fontSize: 14),
                      keyboardType: TextInputType.multiline,
                      // Restrict total characters to 300 (same as posting limit)
                      maxLength: 300,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.chat_hint,
                        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        counterText: '', // hide default counter to keep UI compact
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _canSend ? _handleSend : null,
                  onLongPress: () async {
                    // Open NewPostScreen with current input text and await result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewPostScreen(initialText: _textController.text),
                      ),
                    );

                    // If NewPostScreen returned `true`, a post/draft/scheduled was created — clear input
                    if (result == true) {
                      _textController.clear();
                      setState(() {
                        _selectedImages.clear();
                      });
                      _onTextChanged();
                    } else if (result is String) {
                      // User returned with edited text — synchronize
                      _textController.text = result;
                      // place cursor at end
                      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                      _onTextChanged();
                    }
                  },
                  child: Icon(
                    Icons.send,
                    color: _canSend ? Colors.blue : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
