// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bluesky/app_bsky_embed_images.dart';
import 'package:bluesky/app_bsky_embed_video.dart';
import '../services/bluesky_service.dart';
import '../services/database_service.dart';
import '../utils/avatar_provider.dart';

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
  XFile? _selectedVideo;
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
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.post_image_limit))
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
    if (text.isEmpty && _selectedImages.isEmpty && _selectedVideo == null) return;

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

      EmbedVideo? uploadedVideo;
      if (_selectedVideo != null) {
        final bytes = await _selectedVideo!.readAsBytes();
        final blob = await _service.uploadBlob(bytes);
        uploadedVideo = EmbedVideo(video: blob);
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
        await _service.reply(widget.replyTo!, text, images: uploadedImages, video: uploadedVideo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_reply_success)));
          Navigator.pop(context, true);
        }
      } else if (widget.quoteOf != null) {
        await _service.quote(widget.quoteOf!, text, images: uploadedImages, video: uploadedVideo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_quote_success)));
          Navigator.pop(context, true);
        }
      } else {
        await _service.post(text, images: uploadedImages, video: uploadedVideo);
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
          if (widget.replyTo != null)
            _buildReferencePost(widget.replyTo!, true),
          if (widget.quoteOf != null)
            _buildReferencePost(widget.quoteOf!, false),
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
                  if (_selectedVideo != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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
                              onTap: () => setState(() => _selectedVideo = null),
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
                  icon: Icon(Icons.add, color: theme.colorScheme.primary),
                  onPressed: _showAttachmentMenu,
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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final len = value.text.length;
                    return Text(
                      '$len/300',
                      style: TextStyle(
                        color: len > 300 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
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

  Widget _buildReferencePost(PostItem post, bool isReply) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    if (isReply) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.reply, size: 16, color: secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  '${l10n.post_reply_title} @${post.handle}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: avatarImageProvider(post.avatar),
                              child: post.avatar == null ? const Icon(Icons.person, size: 12) : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.author,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Quote
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  l10n.post_quote_title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: avatarImageProvider(post.avatar),
                  child: post.avatar == null ? const Icon(Icons.person, size: 12) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }
  }
}
