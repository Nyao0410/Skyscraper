import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_item.dart';
import 'media_viewer.dart';
import 'video_player_widget.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItem> media;

  const MediaGrid({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: media.length == 1
            ? _buildSingleMedia(context, media.first)
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.0,
                children: List.generate(media.length, (index) {
                  return _buildMediaItem(context, media, index);
                }),
              ),
      ),
    );
  }

  Widget _buildSingleMedia(BuildContext context, MediaItem item) {
    if (item.type == MediaType.video && item.videoUrl != null) {
      return VideoPlayerWidget(url: item.videoUrl!);
    }

    return GestureDetector(
      onTap: () => _openViewer(context, [item], 0),
      child: Hero(
        tag: item.url,
        child: CachedNetworkImage(
          imageUrl: item.url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            height: 200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade200,
            height: 200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, List<MediaItem> media, int index) {
    final item = media[index];
    return GestureDetector(
      onTap: () => _openViewer(context, media, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: item.url,
            child: CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          if (item.type == MediaType.video)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
            ),
          if (item.alt.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ALT',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, List<MediaItem> media, int index) {
    // If it's a video, we might want different behavior, but for now let's just show images in viewer
    // and handle video playback in the grid or a separate full screen player.
    // Bluesky videos are usually single.
    if (media[index].type == MediaType.video) {
      // Video is already handled by VideoPlayerWidget in _buildSingleMedia
      // If it's in a grid, we might want to open it full screen.
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewer(media: media, initialIndex: index),
      ),
    );
  }
}
