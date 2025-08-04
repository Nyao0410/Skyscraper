
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:skyscraper/models/post.dart';

part 'timeline.freezed.dart';
part 'timeline.g.dart';

@freezed
class Timeline with _$Timeline {
  const factory Timeline({
    required List<Post> posts,
    String? cursor,
  }) = _Timeline;

  factory Timeline.fromJson(Map<String, dynamic> json) =>
      _$TimelineFromJson(json);
}
