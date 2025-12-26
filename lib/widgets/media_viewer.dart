import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/post_item.dart';

class MediaViewer extends StatefulWidget {
  final List<MediaItem> media;
  final int initialIndex;
  final String? heroTagPrefix;

  const MediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

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
          kIsWeb
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.media.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = widget.media[index];
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.network(
                          item.url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    final item = widget.media[index];
                    final heroTag = widget.heroTagPrefix != null ? '${widget.heroTagPrefix}-${item.url}' : item.url;
                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(item.url),
                      initialScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
                    );
                  },
                  itemCount: widget.media.length,
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  pageController: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
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
                    if (widget.media.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.media.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    _AltTextWidget(alt: widget.media[_currentIndex].alt),
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
