import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/api/bluesky_service.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:atproto/atproto.dart' as atp;

final postProvider = StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier(ref.read(blueskyServiceProvider));
});

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  PostNotifier(this._blueskyService) : super(const AsyncData(null));

  final BlueskyService _blueskyService;

  Future<void> createPost(String text, {File? image}) async {
    state = const AsyncValue.loading();
    try {
      bsky.Embed? embed;
      if (image != null) {
        final atp.BlobData response = await _blueskyService.uploadBlob(image.readAsBytesSync());
        embed = bsky.Embed.images(
          data: bsky.EmbedImages(
            images: [bsky.Image(alt: '', image: response.blob)],
          ),
        );
      }
      await _blueskyService.createPost(text, embed: embed);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
