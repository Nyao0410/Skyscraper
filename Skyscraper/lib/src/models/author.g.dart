// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Author _$AuthorFromJson(Map<String, dynamic> json) => _Author(
  handle: json['handle'] as String,
  displayName: json['displayName'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$AuthorToJson(_Author instance) => <String, dynamic>{
  'handle': instance.handle,
  'displayName': instance.displayName,
  'avatar': instance.avatar,
};
