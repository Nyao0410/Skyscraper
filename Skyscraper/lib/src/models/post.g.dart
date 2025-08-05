// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  uri: json['uri'] as String,
  text: json['text'] as String,
  author: Author.fromJson(json['author'] as Map<String, dynamic>),
  likeCount: (json['likeCount'] as num).toInt(),
  repostCount: (json['repostCount'] as num).toInt(),
  createdAt: DateTime.parse(json['indexedAt'] as String),
);

Map<String, dynamic> _$PostToJson(_Post instance) => <String, dynamic>{
  'uri': instance.uri,
  'text': instance.text,
  'author': instance.author,
  'likeCount': instance.likeCount,
  'repostCount': instance.repostCount,
  'indexedAt': instance.createdAt.toIso8601String(),
};
