import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/avatar_provider.dart';
import '../widgets/date_separator.dart';

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
  final String participantHandle;
  final String? participantAvatar;
  final List<DMMessage> messages;
  final bool isRefreshing;
  final Function() onRefresh;
  final Function(String text) onSendMessage;

  const DMDetailScreen({
    super.key,
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
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
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
        backgroundColor: isDark ? const Color(0xFF1A1D21) : const Color(0xFF7494C0),
        appBar: _buildAppBar(),
        body: Column(
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF7494C0);
    final textColor = Colors.white;
    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 1,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: avatarImageProvider(widget.participantAvatar),
            child: widget.participantAvatar == null ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantHandle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.online,
                  style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)),
                ),
              ],
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
    final myBubbleColor = isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
    final otherBubbleColor = isDark ? const Color(0xFF202C33) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final timeColor = isDark ? Colors.white60 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: avatarImageProvider(widget.participantAvatar),
              child: widget.participantAvatar == null ? const Icon(Icons.person, size: 14) : null,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
    final backgroundColor = isDark ? const Color(0xFF202C33) : const Color(0xFFF0F2F5);
    
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3942) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                onChanged: (val) => setState(() => _canSend = val.trim().isNotEmpty),
                decoration: InputDecoration(
                  hintText: l10n.chat_hint,
                  hintStyle: const TextStyle(fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: 5,
                minLines: 1,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _canSend ? const Color(0xFF00A884) : Colors.grey,
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _canSend ? _handleSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
