import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';

class NewPostScreen extends StatefulWidget {
  final String? initialText;
  const NewPostScreen({super.key, this.initialText});

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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now.add(const Duration(minutes: 5)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? now.add(const Duration(minutes: 5))),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _db.saveDraft(text);
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
        await _db.saveDraft(text, scheduledAt: _scheduledDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投稿を予約しました')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規投稿'),
        actions: [
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'いまどうしてる？',
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
}
