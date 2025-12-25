import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
import '../services/background_image_service.dart';

import '../models/post_item.dart';
import '../widgets/message_bubble.dart';
import '../widgets/date_separator.dart';
import 'new_post_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? id;
  final String title;
  final List<PostItem> messages;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Function() onRefresh;
  final Function() onLoadMore;
  final Function(String text, {List<XFile>? images, XFile? video, PostItem? replyTo, PostItem? quoteOf}) onSendMessage;
  final Function(PostItem item)? onLike;
  final Function(PostItem item)? onUnlike;
  final Function(PostItem item)? onRepost;
  final Function(PostItem item)? onUnrepost;
  final Function(PostItem item)? onDelete;

  const ChatScreen({
    super.key,
    this.id,
    this.title = '',
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
    this.onDelete,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  final int _maxChars = 300;
  bool _canSend = false;
  int _remaining = 300;
  PostItem? _replyTo;
  PostItem? _quoteOf;
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _onTextChanged();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.id != null) {
      final path = await BackgroundImageService.getBackgroundImage(widget.id!);
      if (mounted) {
        setState(() {
          _backgroundImagePath = path;
        });
      }
    }
  }

  Future<void> _setBackgroundImage() async {
    if (widget.id == null) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await BackgroundImageService.setBackgroundImage(widget.id!, image.path);
      setState(() {
        _backgroundImagePath = image.path;
      });
    }
  }

  Future<void> _removeBackgroundImage() async {
    if (widget.id == null) return;
    await BackgroundImageService.removeBackgroundImage(widget.id!);
    setState(() {
      _backgroundImagePath = null;
    });
  }

  void _onTextChanged() {
    final len = _textController.text.length;
    final remaining = (_maxChars - len).clamp(0, _maxChars);
    final canSend = (_textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty || _selectedVideo != null) && len <= _maxChars;
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
    if (_selectedVideo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動画と画像は同時に添付できません'))
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

  Future<void> _pickVideo() async {
    if (_selectedImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像と動画は同時に添付できません'))
      );
      return;
    }
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
      });
      _onTextChanged();
    }
  }

  void _showAttachmentMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('画像を選択'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('動画を選択'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    _focusNode.dispose();
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
    if (!_canSend) return;
    final text = _textController.text;
    widget.onSendMessage(
      text,
      images: _selectedImages.isEmpty ? null : List.from(_selectedImages),
      video: _selectedVideo,
      replyTo: _replyTo,
      quoteOf: _quoteOf,
    );
    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedVideo = null;
      _replyTo = null;
      _quoteOf = null;
    });
    _onTextChanged();
  }

  void _setReplyTo(PostItem? item) {
    setState(() {
      _replyTo = item;
      _quoteOf = null; // Clear quote if replying
    });
    if (item != null) {
      _focusNode.requestFocus();
    }
  }

  void _setQuoteOf(PostItem? item) {
    setState(() {
      _quoteOf = item;
      _replyTo = null; // Clear reply if quoting
    });
    if (item != null) {
      _focusNode.requestFocus();
    }
  }

  void _insertTagToComposer(String tag) {
    final normalized = tag.startsWith('#') ? tag : '#$tag';
    final current = _textController.text;
    final needsSpace = current.isNotEmpty && !current.endsWith(' ');
    final newText = current + (needsSpace ? ' ' : '') + normalized;
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    _onTextChanged();
    // Ensure the composer has focus for better UX
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // debugPrint('ChatScreen build: ${widget.messages.length} messages, refreshing: ${widget.isRefreshing}');
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: _backgroundImagePath != null,
        backgroundColor: isDark ? const Color(0xFF1A1D21) : const Color(0xFF7494C0),
        appBar: _buildAppBar(),
        body: Container(
          decoration: _backgroundImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(_backgroundImagePath!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: isDark ? 0.6 : 0.3),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => widget.onRefresh(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF7494C0);
    final textColor = Colors.white;

    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: _backgroundImagePath != null ? Colors.transparent : appBarColor,
      elevation: _backgroundImagePath != null ? 0 : 1,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        title: Text(
          widget.title.isNotEmpty ? widget.title : l10n.chat_default_title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          overflow: TextOverflow.ellipsis,
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
        if (widget.id != null)
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: textColor),
            onSelected: (value) {
              if (value == 'set_bg') {
                _setBackgroundImage();
              } else if (value == 'remove_bg') {
                _removeBackgroundImage();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'set_bg',
                child: Row(
                  children: [
                    Icon(Icons.image, size: 20),
                    SizedBox(width: 8),
                    Text('背景画像を設定'),
                  ],
                ),
              ),
              if (_backgroundImagePath != null)
                const PopupMenuItem(
                  value: 'remove_bg',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('背景画像を削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
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
                onReply: _setReplyTo,
                onQuote: _setQuoteOf,
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
          onReply: _setReplyTo,
          onQuote: _setQuoteOf,
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
            if (_replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: avatarImageProvider(_replyTo!.avatar),
                      child: _replyTo!.avatar == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_replyTo!.author} (@${_replyTo!.handle})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            _replyTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _setReplyTo(null),
                    ),
                  ],
                ),
              ),
            if (_quoteOf != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: Colors.green, width: 4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: avatarImageProvider(_quoteOf!.avatar),
                      child: _quoteOf!.avatar == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_quote, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${_quoteOf!.author} (@${_quoteOf!.handle})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _quoteOf!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _setQuoteOf(null),
                    ),
                  ],
                ),
              ),
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
            if (_selectedVideo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.videocam, color: Colors.white, size: 48),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedVideo = null);
                          _onTextChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: isDark ? Colors.white : Colors.black),
                  onPressed: _showAttachmentMenu,
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
                      focusNode: _focusNode,
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
                        hintText: _replyTo != null 
                            ? l10n.reply_to(_replyTo!.handle) 
                            : (_quoteOf != null ? l10n.timeline_quote_post : l10n.chat_hint),
                        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        counterText: '', // hide default counter to keep UI compact
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: _remaining < 20 ? Colors.red : textColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
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
                  child: IconButton(
                    onPressed: _canSend ? _handleSend : null,
                    icon: const Icon(Icons.send, size: 28),
                    color: _canSend ? Colors.blue : Colors.grey,
                    disabledColor: Colors.grey.shade400,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
