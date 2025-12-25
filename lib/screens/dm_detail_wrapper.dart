import 'dart:async';
import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../services/bluesky_service.dart';
import 'dm_detail_screen.dart';

class DMDetailWrapper extends StatefulWidget {
  final String participantDid;
  final String participantHandle;
  final String? participantAvatar;
  final String? convoId;

  const DMDetailWrapper({
    super.key,
    required this.participantDid,
    required this.participantHandle,
    this.participantAvatar,
    this.convoId,
  });

  @override
  State<DMDetailWrapper> createState() => _DMDetailWrapperState();
}

class _DMDetailWrapperState extends State<DMDetailWrapper> {
  final _service = BlueskyService();
  List<DMMessage> _messages = [];
  bool _loading = true;
  String? _convoId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _convoId = widget.convoId;
    _loadMessages();
    // Start periodic polling to refresh messages (every 10 seconds)
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      // avoid starting a new load while one is in progress
      if (!_loading) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _loading = true);
      
      // Ensure conversation exists and get convoId
      _convoId ??= await _service.startDMConversation(widget.participantDid);

      if (_convoId == null) {
        throw Exception('Could not start conversation');
      }
      
      final data = await _service.getDMMessages(_convoId!);
      if (mounted) {
        setState(() {
          _messages = data.map((m) => DMMessage(
            id: m['id'],
            senderDid: m['sender_did'],
            text: m['text'],
            sentAt: DateTime.parse(m['sent_at']),
            isMe: m['sender_did'] == _service.did,
            status: m['status'] ?? 'sent',
          )).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dm_fetch_error(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (_convoId == null) return;
    try {
      await _service.sendDM(_convoId!, text);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dm_send_error(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _messages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.participantHandle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DMDetailScreen(
      id: _convoId ?? widget.participantDid,
      participantHandle: widget.participantHandle,
      participantAvatar: widget.participantAvatar,
      messages: _messages,
      isRefreshing: _loading,
      onRefresh: _loadMessages,
      onSendMessage: _handleSendMessage,
    );
  }
}
