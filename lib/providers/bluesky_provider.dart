
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/providers/session_provider.dart';

final blueskyProvider = Provider<bsky.Bluesky>((ref) {
  final session = ref.watch(sessionProvider);

  if (session == null) {
    throw Exception('Not authenticated');
  }

  return bsky.Bluesky.fromSession(session);
});
