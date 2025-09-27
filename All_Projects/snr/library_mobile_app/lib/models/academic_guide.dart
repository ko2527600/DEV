import 'package:json_annotation/json_annotation.dart';

part 'academic_guide.g.dart';

@JsonSerializable()
class AcademicGuide {
  final String id;
  final String title;
  final String category;
  final String content;
  final String? author;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AcademicGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.author,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating from JSON
  factory AcademicGuide.fromJson(Map<String, dynamic> json) =>
      _$AcademicGuideFromJson(json);

  // Method for converting to JSON
  Map<String, dynamic> toJson() => _$AcademicGuideToJson(this);

  // Copy with method for creating modified copies
  AcademicGuide copyWith({
    String? id,
    String? title,
    String? category,
    String? content,
    String? author,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicGuide(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      content: content ?? this.content,
      author: author ?? this.author,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AcademicGuide &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.content == content &&
        other.author == author &&
        other.isPublished == isPublished &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  // Hash code
  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      category,
      content,
      author,
      isPublished,
      createdAt,
      updatedAt,
    );
  }

  // String representation
  @override
  String toString() {
    return 'AcademicGuide(id: $id, title: $title, category: $category, content: $content, author: $author, isPublished: $isPublished, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  // Static methods for common operations
  static List<AcademicGuide> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AcademicGuide.fromJson(json)).toList();
  }

  // Category constants
  static const String categoryConduct = 'Conduct';
  static const String categoryRelationships = 'Relationships';
  static const String categoryStudySkills = 'Study Skills';
  static const String categoryWriting = 'Writing';
  static const String categoryResearch = 'Research';
  static const String categoryTimeManagement = 'Time Management';
  static const String categoryAcademicIntegrity = 'Academic Integrity';
  static const String categoryProfessionalDevelopment = 'Professional Development';

  // Get all available categories
  static List<String> get allCategories => [
        categoryConduct,
        categoryRelationships,
        categoryStudySkills,
        categoryWriting,
        categoryResearch,
        categoryTimeManagement,
        categoryAcademicIntegrity,
        categoryProfessionalDevelopment,
      ];

  // Get category display name
  String get categoryDisplayName {
    switch (category) {
      case categoryConduct:
        return 'Member Conduct';
      case categoryRelationships:
        return 'Teacher Relationships';
      case categoryStudySkills:
        return 'Study Skills';
      case categoryWriting:
        return 'Academic Writing';
      case categoryResearch:
        return 'Research Methods';
      case categoryTimeManagement:
        return 'Time Management';
      case categoryAcademicIntegrity:
        return 'Academic Integrity';
      case categoryProfessionalDevelopment:
        return 'Professional Development';
      default:
        return category;
    }
  }

  // Get category icon
  String get categoryIcon {
    switch (category) {
      case categoryConduct:
        return 'gavel';
      case categoryRelationships:
        return 'people';
      case categoryStudySkills:
        return 'school';
      case categoryWriting:
        return 'edit';
      case categoryResearch:
        return 'search';
      case categoryTimeManagement:
        return 'schedule';
      case categoryAcademicIntegrity:
        return 'verified';
      case categoryProfessionalDevelopment:
        return 'trending_up';
      default:
        return 'article';
    }
  }

  // Get category color (Material Design colors)
  int get categoryColor {
    switch (category) {
      case categoryConduct:
        return 0xFFE53935; // Red
      case categoryRelationships:
        return 0xFF2196F3; // Blue
      case categoryStudySkills:
        return 0xFF4CAF50; // Green
      case categoryWriting:
        return 0xFF9C27B0; // Purple
      case categoryResearch:
        return 0xFFFF9800; // Orange
      case categoryTimeManagement:
        return 0xFF607D8B; // Blue Grey
      case categoryAcademicIntegrity:
        return 0xFF00BCD4; // Cyan
      case categoryProfessionalDevelopment:
        return 0xFF8BC34A; // Light Green
      default:
        return 0xFF795548; // Brown
    }
  }

  // Check if guide is recent (created within last 30 days)
  bool get isRecent {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return createdAt.isAfter(thirtyDaysAgo);
  }

  // Get formatted creation date
  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Get content preview (first 100 characters)
  String get contentPreview {
    if (content.length <= 100) {
      return content;
    }
    return '${content.substring(0, 100)}...';
  }

  // Check if content is long (more than 200 characters)
  bool get hasLongContent => content.length > 200;
}

