// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  author: Actor.fromJson(json['author'] as Map<String, dynamic>),
  text: json['text'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  viewer: json['viewer'] == null
      ? null
      : PostViewer.fromJson(json['viewer'] as Map<String, dynamic>),
  uri: json['uri'] as String,
  cid: json['cid'] as String,
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'author': instance.author,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'viewer': instance.viewer,
      'uri': instance.uri,
      'cid': instance.cid,
    };

_$ActorImpl _$$ActorImplFromJson(Map<String, dynamic> json) => _$ActorImpl(
  did: json['did'] as String,
  handle: json['handle'] as String,
  displayName: json['displayName'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$$ActorImplToJson(_$ActorImpl instance) =>
    <String, dynamic>{
      'did': instance.did,
      'handle': instance.handle,
      'displayName': instance.displayName,
      'avatar': instance.avatar,
    };

_$PostViewerImpl _$$PostViewerImplFromJson(Map<String, dynamic> json) =>
    _$PostViewerImpl(like: json['like'] as String?);

Map<String, dynamic> _$$PostViewerImplToJson(_$PostViewerImpl instance) =>
    <String, dynamic>{'like': instance.like};
