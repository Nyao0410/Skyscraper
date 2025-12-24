import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_item.dart';
import 'media_viewer.dart';
import 'video_player_widget.dart';

class MediaGrid extends StatefulWidget {
  final List<MediaItem> media;
  final List<String> postLabels;
  final String? heroTagPrefix;

  const MediaGrid({
    super.key,
    required this.media,
    this.postLabels = const [],
    this.heroTagPrefix,
  });

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  bool _revealed = false;

  bool get _isSensitive {
    final sensitiveLabels = {
      'porn',
      'nudity',
      'sexual',
      'graphic-media',
      'violence',
      'sensitive',
      '!warn',
    };
    
    if (widget.postLabels.any((l) => sensitiveLabels.contains(l.toLowerCase()))) {
      return true;
    }
    
    return widget.media.any((m) => m.labels.any((l) => sensitiveLabels.contains(l.toLowerCase())));
  }

  String get _warningText {
    final allLabels = {
      ...widget.postLabels.map((l) => l.toLowerCase()),
      ...widget.media.expand((m) => m.labels.map((l) => l.toLowerCase()))
    };
    
    if (allLabels.contains('porn') || allLabels.contains('nudity') || allLabels.contains('sexual')) {
      return 'Adult Content';
    }
    if (allLabels.contains('graphic-media') || allLabels.contains('violence')) {
      return 'Graphic Content';
    }
    return 'Content Warning';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    if (_isSensitive && !_revealed) {
      return _buildWarning(context);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.media.length == 1
            ? _buildSingleMedia(context, widget.media.first)
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1.0,
                children: List.generate(widget.media.length, (index) {
                  return _buildMediaItem(context, widget.media, index);
                }),
              ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => setState(() => _revealed = true),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                _warningText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to show',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleMedia(BuildContext context, MediaItem item) {
    if (item.type == MediaType.video && item.videoUrl != null) {
      return VideoPlayerWidget(url: item.videoUrl!);
    }

    final heroTag = widget.heroTagPrefix != null ? '${widget.heroTagPrefix}-${item.url}' : item.url;

    return GestureDetector(
      onTap: () => _openViewer(context, [item], 0),
      child: Hero(
        tag: heroTag,
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
    final heroTag = widget.heroTagPrefix != null ? '${widget.heroTagPrefix}-${item.url}' : item.url;

    return GestureDetector(
      onTap: () => _openViewer(context, media, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: heroTag,
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
    if (media[index].type == MediaType.video) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewer(
          media: media,
          initialIndex: index,
          heroTagPrefix: widget.heroTagPrefix,
        ),
      ),
    );
  }
}
