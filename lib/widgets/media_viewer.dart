import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/post_item.dart';

class MediaViewer extends StatelessWidget {
  final List<MediaItem> media;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(media[index].url),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: media[index].url),
              );
            },
            itemCount: media.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {
              // Could update state if we wanted to show index
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (media.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${initialIndex + 1} / ${media.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    _AltTextWidget(alt: media[initialIndex].alt),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AltTextWidget extends StatefulWidget {
  final String alt;
  const _AltTextWidget({required this.alt});

  @override
  State<_AltTextWidget> createState() => _AltTextWidgetState();
}

class _AltTextWidgetState extends State<_AltTextWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.alt.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ALT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.alt,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
