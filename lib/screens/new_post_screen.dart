// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bluesky/app_bsky_embed_images.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';

import '../models/post_item.dart';

class NewPostScreen extends StatefulWidget {
  final String? initialText;
  final PostItem? replyTo;
  final PostItem? quoteOf;
  final int? draftId;
  final DateTime? scheduledAt;
  final bool preferDraft; // if true, primary action defaults to saving draft
  
  const NewPostScreen({
    super.key, 
    this.initialText,
    this.replyTo,
    this.quoteOf,
    this.draftId,
    this.scheduledAt,
    this.preferDraft = false,
  });

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _controller = TextEditingController();
  final _service = BlueskyService();
  final _db = DatabaseService();
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  DateTime? _scheduledDate;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
    if (widget.scheduledAt != null) {
      _scheduledDate = widget.scheduledAt;
    }
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.post_image_limit))
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
    }
  }

  Future<void> _selectSchedule() async {
    final l10n = AppLocalizations.of(context);
    if (widget.replyTo != null) {
      // Capture messenger synchronously to avoid using BuildContext across async gaps
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.post_reply_schedule_not_supported))
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
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // For simplicity, we only save text drafts for now
    if (widget.draftId != null) {
      await _db.updateDraft(widget.draftId!, text, scheduledAt: _scheduledDate);
    } else {
      await _db.saveDraft(_service.did!, text, scheduledAt: _scheduledDate);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_draft_saved)));
      Navigator.pop(context, true);
    }
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      List<EmbedImagesImage>? uploadedImages;
      if (_selectedImages.isNotEmpty) {
        uploadedImages = [];
        for (final image in _selectedImages) {
          final bytes = await image.readAsBytes();
          final blob = await _service.uploadBlob(bytes);
          uploadedImages.add(EmbedImagesImage(image: blob, alt: ''));
        }
      }

      if (_scheduledDate != null) {
        if (widget.draftId != null) {
          await _db.updateDraft(widget.draftId!, text, scheduledAt: _scheduledDate);
        } else {
          await _db.saveDraft(_service.did!, text, scheduledAt: _scheduledDate);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_scheduled_success)));
          Navigator.pop(context, true);
        }
      } else if (widget.replyTo != null) {
        await _service.reply(widget.replyTo!, text, images: uploadedImages);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_reply_success)));
          Navigator.pop(context, true);
        }
      } else if (widget.quoteOf != null) {
        await _service.quote(widget.quoteOf!, text, images: uploadedImages);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_quote_success)));
          Navigator.pop(context, true);
        }
      } else {
        await _service.post(text, images: uploadedImages);
        if (widget.draftId != null) {
          // mark existing draft as sent
          await _db.markAsSent(widget.draftId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_success)));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error_with_message(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bool isDraftMode = widget.preferDraft || widget.draftId != null;
    String title = l10n.post_new_title;
    if (widget.draftId != null) title = l10n.post_edit_draft_title;
    if (widget.replyTo != null) title = l10n.post_reply_title;
    if (widget.quoteOf != null) title = l10n.post_quote_title;

    return WillPopScope(
      onWillPop: () async {
        // Return current text when user navigates back without posting
        Navigator.pop(context, _controller.text);
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
        title: Text(title),
        actions: [
          if (!isDraftMode && widget.replyTo == null && widget.quoteOf == null)
            TextButton(
              onPressed: _isPosting ? null : _saveDraft,
              child: Text(l10n.post_draft_button),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _isPosting
                  ? null
                  : (isDraftMode ? _saveDraft : _post),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C300),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    // If in draft mode, primary action is to save draft
                    isDraftMode
                        ? l10n.post_save_draft_button
                        : (_scheduledDate != null ? l10n.post_schedule_button : l10n.post_button),
                  ),
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
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.replyTo != null ? l10n.post_hint_reply : l10n.post_hint_default,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
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
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImages.removeAt(index)),
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
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: theme.colorScheme.primary),
                  onPressed: _pickImages,
                ),
                if (widget.replyTo == null && widget.quoteOf == null)
                  IconButton(
                    icon: Icon(
                      Icons.schedule,
                      color: _scheduledDate != null ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                    onPressed: _selectSchedule,
                  ),
                if (_scheduledDate != null) ...[
                  Text(
                    DateFormat('MM/dd HH:mm').format(_scheduledDate!),
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
                    onPressed: () => setState(() => _scheduledDate = null),
                  ),
                ],
                const Spacer(),
                Text(
                  '${_controller.text.length}/300',
                  style: TextStyle(
                    color: _controller.text.length > 300 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    )
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
