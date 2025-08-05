import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:skyscraper/src/models/post.dart';
import 'package:skyscraper/src/repositories/timeline_repository.dart';

// assets/json/fake_timeline.json を読み込んで返すだけの偽物のリポジトリ
class FakeTimelineRepository implements ITimelineRepository {
  @override
  Future<List<Post>> fetchTimeline({String? cursor}) async {
    // 意図的にネットワーク遅延をシミュレートする
    await Future.delayed(const Duration(milliseconds: 500));

    final jsonString = await rootBundle.loadString('assets/json/fake_timeline.json');
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // BlueskyのAPIレスポンスは 'feed' というキーに投稿リストが入っている想定
    final feed = jsonMap['feed'] as List;

    // 実際のレスポンスでは投稿情報は 'post' キーの中に入っている想定
    return feed
        .map((item) => Post.fromJson(item['post'] as Map<String, dynamic>))
        .toList();
  }
}
