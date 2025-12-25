import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/bluesky_service.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final dynamic profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = BlueskyService();
  final _picker = ImagePicker();
  
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  
  XFile? _newAvatar;
  XFile? _newBanner;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _descriptionController = TextEditingController(text: widget.profile.description);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newAvatar = image);
    }
  }

  Future<void> _pickBanner() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newBanner = image);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      dynamic avatarBlob;
      if (_newAvatar != null) {
        final bytes = await _newAvatar!.readAsBytes();
        avatarBlob = await _service.uploadBlob(bytes);
      }

      dynamic bannerBlob;
      if (_newBanner != null) {
        final bytes = await _newBanner!.readAsBytes();
        bannerBlob = await _service.uploadBlob(bytes);
      }

      await _service.updateProfile(
        displayName: _displayNameController.text,
        description: _descriptionController.text,
        avatar: avatarBlob,
        banner: bannerBlob,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_with_message(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_edit_title),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner
            GestureDetector(
              onTap: _pickBanner,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_newBanner != null)
                      Image.file(File(_newBanner!.path), fit: BoxFit.cover)
                    else if (widget.profile.banner != null)
                      CachedNetworkImage(imageUrl: widget.profile.banner!, fit: BoxFit.cover)
                    else
                      const Icon(Icons.add_a_photo, size: 40, color: Colors.white),
                    Container(color: Colors.black26),
                    const Center(child: Icon(Icons.camera_alt, color: Colors.white, size: 30)),
                  ],
                ),
              ),
            ),
            // Avatar
            Transform.translate(
              offset: const Offset(0, -40),
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                        backgroundImage: _newAvatar != null
                            ? FileImage(File(_newAvatar!.path))
                            : (widget.profile.avatar != null
                                ? NetworkImage(widget.profile.avatar!)
                                : null) as ImageProvider?,
                        child: (_newAvatar == null && widget.profile.avatar == null)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: l10n.profile_display_name,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.profile_description,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
