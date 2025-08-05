import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/timeline_repository.dart';

/// A fake implementation of [ITimelineRepository] that reads data from a
/// local JSON file.
class FakeTimelineRepository implements ITimelineRepository {
  @override
  Future<List<Post>> fetchTimeline({String? cursor}) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final jsonString = await rootBundle.loadString(
      'assets/json/fake_timeline.json',
    );
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Bluesky API response is expected to have a 'feed' key containing a
    // list of posts.
    final feed = jsonMap['feed'] as List<dynamic>;

    // In the actual response, post information is expected to be inside the
    // 'post' key.
    return feed
        .map((dynamic item) {
          final postMap = item as Map<String, dynamic>;
          return Post.fromJson(postMap['post'] as Map<String, dynamic>);
        })
        .toList();
  }
}
