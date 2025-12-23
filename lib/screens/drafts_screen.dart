import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/bluesky_service.dart';
import 'new_post_screen.dart';

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
    final drafts = await _db.getDrafts(_service.did!);
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _loading = false;
      });
    }
  }

  Future<void> _sendDraft(Map<String, dynamic> draft) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _service.post(draft['text']);
      await _db.markAsSent(draft['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_success)));
        _loadDrafts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.others_drafts),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to new post screen and refresh list after returning
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPostScreen(preferDraft: true)),
          );
          if (res != null) {
            _loadDrafts();
          }
        },
        backgroundColor: const Color(0xFF00C300),
        child: const Icon(Icons.create),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(child: Text(l10n.drafts_no_drafts))
              : ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    final scheduledAt = draft['scheduled_at'] != null 
                      ? DateTime.parse(draft['scheduled_at']).toLocal()
                      : null;
                    
                    return ListTile(
                      title: Text(draft['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.drafts_created_at(DateFormat('MM/dd HH:mm').format(DateTime.parse(draft['created_at'])))),
                          if (scheduledAt != null)
                            Text(
                              l10n.drafts_scheduled_at(DateFormat('MM/dd HH:mm').format(scheduledAt)),
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      onTap: () async {
                        // Open NewPostScreen for editing this draft
                        final id = draft['id'] as int?;
                        final text = draft['text'] as String?;
                        final sched = draft['scheduled_at'] != null ? DateTime.parse(draft['scheduled_at']).toLocal() : null;
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NewPostScreen(initialText: text, draftId: id, scheduledAt: sched, preferDraft: true)),
                        );
                        if (res != null) {
                          _loadDrafts();
                        }
                      },
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
