class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? courseCode;
  final String? courseName;
  final String category; // 'course' or 'life'
  final String subject; // 'Mathematics', 'Science', 'Literature', 'Self-Help', etc.
  final String? description;
  final String? coverImageUrl;
  final String? bookFileUrl; // URL to the actual book file (PDF, EPUB, etc.)
  final String bookFormat; // 'pdf', 'epub', 'mobi', etc.
  final int fileSize; // File size in bytes
  final int totalCopies;
  final int availableCopies;
  final String location; // Shelf location
  final DateTime? publicationYear;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.courseCode,
    this.courseName,
    required this.category,
    required this.subject,
    this.description,
    this.coverImageUrl,
    this.bookFileUrl,
    this.bookFormat = 'pdf',
    this.fileSize = 0,
    required this.totalCopies,
    required this.availableCopies,
    required this.location,
    this.publicationYear,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => availableCopies > 0;
  bool get isCourseBook => category == 'course';
  bool get isLifeBook => category == 'life';

  factory Book.fromJson(Map<String, dynamic> json) {
    try {
      // Check for required fields
      final requiredFields = ['id', 'title', 'author', 'category', 'subject', 'total_copies', 'available_copies', 'location', 'created_at', 'updated_at'];
      for (final field in requiredFields) {
        if (json[field] == null) {
          throw Exception('Missing required field: $field in book data');
        }
      }
      
             return Book(
         id: json['id'].toString(),
         title: json['title'].toString(),
         author: json['author'].toString(),
         isbn: json['isbn']?.toString(),
         courseCode: json['course_code']?.toString(),
         courseName: json['course_name']?.toString(),
         category: json['category'].toString(),
         subject: json['subject'].toString(),
         description: json['description']?.toString(),
         coverImageUrl: json['cover_url']?.toString(), // Fixed: use cover_url from database
         bookFileUrl: json['file_url']?.toString(), // Fixed: use file_url from database
         bookFormat: json['book_format']?.toString() ?? 'pdf',
         fileSize: int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
         totalCopies: int.tryParse(json['total_copies'].toString()) ?? 0,
         availableCopies: int.tryParse(json['available_copies'].toString()) ?? 0,
         location: json['location'].toString(),
         publicationYear: json['publication_year'] != null 
             ? DateTime.tryParse(json['publication_year'].toString()) 
             : null,
         createdAt: DateTime.parse(json['created_at'].toString()),
         updatedAt: DateTime.parse(json['updated_at'].toString()),
       );
    } catch (e) {
      print('💥 Error parsing book JSON: $e');
      print('📄 Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'course_code': courseCode,
      'course_name': courseName,
      'category': category,
      'subject': subject,
      'description': description,
      'cover_url': coverImageUrl, // Fixed: use cover_url for database
      'file_url': bookFileUrl, // Fixed: use file_url for database
      'book_format': bookFormat,
      'file_size': fileSize,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'location': location,
      'publication_year': publicationYear?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? courseCode,
    String? courseName,
    String? category,
    String? subject,
    String? description,
    String? coverImageUrl,
    String? bookFileUrl,
    String? bookFormat,
    int? fileSize,
    int? totalCopies,
    int? availableCopies,
    String? location,
    DateTime? publicationYear,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bookFileUrl: bookFileUrl ?? this.bookFileUrl,
      bookFormat: bookFormat ?? this.bookFormat,
      fileSize: fileSize ?? this.fileSize,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      location: location ?? this.location,
      publicationYear: publicationYear ?? this.publicationYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
