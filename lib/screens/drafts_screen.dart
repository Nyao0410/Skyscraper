import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/bluesky_service.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _db = DatabaseService();
  final _service = BlueskyService();
  List<Map<String, dynamic>> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _loading = true);
    final drafts = await _db.getDrafts();
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _loading = false;
      });
    }
  }

  Future<void> _sendDraft(Map<String, dynamic> draft) async {
    try {
      await _service.post(draft['text']);
      await _db.markAsSent(draft['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投稿しました')));
        _loadDrafts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下書き・予約投稿'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? const Center(child: Text('下書きはありません'))
              : ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    final scheduledAt = draft['scheduled_at'] != null 
                        ? DateTime.parse(draft['scheduled_at']) 
                        : null;
                    
                    return ListTile(
                      title: Text(draft['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('作成: ${DateFormat('MM/dd HH:mm').format(DateTime.parse(draft['created_at']))}'),
                          if (scheduledAt != null)
                            Text(
                              '予約: ${DateFormat('MM/dd HH:mm').format(scheduledAt)}',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _sendDraft(draft),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await _db.deleteDraft(draft['id']);
                              _loadDrafts();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
