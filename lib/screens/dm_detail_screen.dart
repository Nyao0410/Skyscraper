import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
import '../widgets/date_separator.dart';
import '../services/background_image_service.dart';

class DMMessage {
  final String id;
  final String senderDid;
  final String text;
  final DateTime sentAt;
  final bool isMe;
  final String status; // 'sent', 'pending', 'failed'

  DMMessage({
    required this.id,
    required this.senderDid,
    required this.text,
    required this.sentAt,
    required this.isMe,
    this.status = 'sent',
  });
}

class DMDetailScreen extends StatefulWidget {
  final String? id;
  final String participantHandle;
  final String? participantAvatar;
  final List<DMMessage> messages;
  final bool isRefreshing;
  final Function() onRefresh;
  final Function(String text) onSendMessage;

  const DMDetailScreen({
    super.key,
    this.id,
    required this.participantHandle,
    this.participantAvatar,
    required this.messages,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onSendMessage,
  });

  @override
  State<DMDetailScreen> createState() => _DMDetailScreenState();
}

class _DMDetailScreenState extends State<DMDetailScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  bool _canSend = false;
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
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
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _textController.clear();
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    image: kIsWeb
                        ? NetworkImage(_backgroundImagePath!)
                        : FileImage(File(_backgroundImagePath!)) as ImageProvider,
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
    return AppBar(
      backgroundColor: _backgroundImagePath != null ? Colors.transparent : appBarColor,
      elevation: _backgroundImagePath != null ? 0 : 1,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          kIsWeb
              ? ClipOval(
                  child: widget.participantAvatar != null && widget.participantAvatar!.isNotEmpty
                      ? Image.network(
                          widget.participantAvatar!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 16),
                          ),
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 16),
                        ),
                )
              : buildAvatar(
                  widget.participantAvatar,
                  size: 32,
                  backgroundColor: Colors.grey[300],
                  placeholder: const Icon(Icons.person, size: 16),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.participantHandle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
            widget.isRefreshing ? Icons.sync : Icons.mail_outline,
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
    final sortedMessages = List<DMMessage>.from(widget.messages)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        
        bool showDateSeparator = false;
        if (index == sortedMessages.length - 1) {
          showDateSeparator = true;
        } else {
          final nextMessage = sortedMessages[index + 1];
          if (message.sentAt.year != nextMessage.sentAt.year ||
              message.sentAt.month != nextMessage.sentAt.month ||
              message.sentAt.day != nextMessage.sentAt.day) {
            showDateSeparator = true;
          }
        }

        return Column(
          children: [
            if (showDateSeparator) DateSeparator(date: message.sentAt),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(DMMessage message) {
    final isMe = message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors matching ChatScreen/MessageBubble
    final myBubbleColor = const Color(0xFF8DE055);
    final otherBubbleColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isMe ? Colors.black : (isDark ? Colors.white : Colors.black87);
    final timeColor = isMe ? Colors.black54 : (isDark ? Colors.white60 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            kIsWeb
                ? ClipOval(
                    child: widget.participantAvatar != null && widget.participantAvatar!.isNotEmpty
                        ? Image.network(
                            widget.participantAvatar!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 28,
                              height: 28,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 14),
                            ),
                          )
                        : Container(
                            width: 28,
                            height: 28,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 14),
                          ),
                  )
                : buildAvatar(
                    widget.participantAvatar,
                    size: 28,
                    backgroundColor: Colors.grey[300],
                    placeholder: const Icon(Icons.person, size: 14),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? myBubbleColor : otherBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(color: timeColor, fontSize: 10),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(message),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(DMMessage message) {
    if (message.status == 'pending') {
      return const Icon(Icons.access_time, size: 12, color: Colors.grey);
    } else if (message.status == 'failed') {
      return const Icon(Icons.error_outline, size: 12, color: Colors.red);
    } else {
      return const Icon(Icons.done_all, size: 12, color: Colors.blue);
    }
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                // DM doesn't support attachments yet in this app, 
                // but we show the icon for UI consistency.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('DMでの添付ファイルは現在サポートされていません')),
                );
              },
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
                  onChanged: (val) => setState(() => _canSend = val.trim().isNotEmpty),
                  decoration: InputDecoration(
                    hintText: l10n.chat_hint,
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _canSend ? _handleSend : null,
              icon: Icon(Icons.send, size: 28),
              color: _canSend ? Colors.blue : Colors.grey.shade400,
              disabledColor: Colors.grey.shade400,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }
}
