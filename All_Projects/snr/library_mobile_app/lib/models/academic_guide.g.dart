// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_guide.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcademicGuide _$AcademicGuideFromJson(Map<String, dynamic> json) =>
    AcademicGuide(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      author: json['author'] as String?,
      isPublished: json['isPublished'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AcademicGuideToJson(AcademicGuide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'content': instance.content,
      'author': instance.author,
      'isPublished': instance.isPublished,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
