// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';

import '../models/post_item.dart';

class NewPostScreen extends StatefulWidget {
  final String? initialText;
  final PostItem? replyTo;
  final PostItem? quoteOf;
  
  const NewPostScreen({
    super.key, 
    this.initialText,
    this.replyTo,
    this.quoteOf,
  });

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _controller = TextEditingController();
  final _service = BlueskyService();
  final _db = DatabaseService();
  DateTime? _scheduledDate;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  Future<void> _selectSchedule() async {
    if (widget.replyTo != null) {
      // Capture messenger synchronously to avoid using BuildContext across async gaps
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('返信の予約投稿は現在サポートされていません'))
      );
      return;
    }
    final now = DateTime.now();
    final ctx = context;
    final date = await showDatePicker(
      context: ctx,
      initialDate: _scheduledDate ?? now.add(const Duration(minutes: 5)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? now.add(const Duration(minutes: 5))),
      );
      if (time != null) {
        if (!mounted) return;
        setState(() {
          _scheduledDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // For simplicity, we only save text drafts for now
    await _db.saveDraft(_service.did!, text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下書きを保存しました')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      if (_scheduledDate != null) {
        await _db.saveDraft(_service.did!, text, scheduledAt: _scheduledDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投稿を予約しました')));
          Navigator.pop(context, true);
        }
      } else if (widget.replyTo != null) {
        await _service.reply(widget.replyTo!, text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('返信しました')));
          Navigator.pop(context, true);
        }
      } else if (widget.quoteOf != null) {
        await _service.quote(widget.quoteOf!, text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('引用投稿しました')));
          Navigator.pop(context, true);
        }
      } else {
        await _service.post(text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投稿しました')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '新規投稿';
    if (widget.replyTo != null) title = '返信';
    if (widget.quoteOf != null) title = '引用';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.replyTo == null && widget.quoteOf == null)
            TextButton(
              onPressed: _isPosting ? null : _saveDraft,
              child: const Text('下書き'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C300),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_scheduledDate != null ? '予約' : '投稿'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.replyTo != null || widget.quoteOf != null)
            _buildReferencePost(widget.replyTo ?? widget.quoteOf!),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.replyTo != null ? '返信を入力...' : 'いまどうしてる？',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                if (widget.replyTo == null && widget.quoteOf == null)
                  IconButton(
                    icon: Icon(Icons.schedule, color: _scheduledDate != null ? Colors.blue : Colors.grey),
                    onPressed: _selectSchedule,
                  ),
                if (_scheduledDate != null) ...[
                  Text(
                    DateFormat('MM/dd HH:mm').format(_scheduledDate!),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.blue),
                    onPressed: () => setState(() => _scheduledDate = null),
                  ),
                ],
                const Spacer(),
                Text(
                  '${_controller.text.length}/300',
                  style: TextStyle(
                    color: _controller.text.length > 300 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencePost(PostItem post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.avatar != null)
                CircleAvatar(radius: 10, backgroundImage: NetworkImage(post.avatar!))
              else
                const Icon(Icons.account_circle, size: 20),
              const SizedBox(width: 8),
              Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
