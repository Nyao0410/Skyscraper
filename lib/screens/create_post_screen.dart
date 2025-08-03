import 'dart:io';

import 'package:bluesky_text/bluesky_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skyscraper/providers/post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final BlueskyText _blueskyText = const BlueskyText('');
  File? _image;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        // No need to parse here, just to trigger rebuild
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 300 - _blueskyText.length;
    final postState = ref.watch(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: postState.isLoading || remaining < 0
                ? null
                : () async {
                    await ref.read(postProvider.notifier).createPost(
                          _textController.text,
                          image: _image,
                        );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: postState.isLoading
                ? const CircularProgressIndicator()
                : const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'What is happening?!',
                border: InputBorder.none,
              ),
            ),
            if (_image != null)
              Stack(
                children: [
                  Image.file(_image!),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        setState(() {
                          _image = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                const Spacer(),
                Text(
                  '$remaining',
                  style: TextStyle(
                    color: remaining < 0 ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
