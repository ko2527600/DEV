import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/book.dart';
import '../models/user.dart' as app_user;
import '../models/loan.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  void initialize(SupabaseClient client) {
    _client = client;
  }

  SupabaseClient get client => _client;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  app_user.User? get currentUser {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    
    return app_user.User(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: authUser.userMetadata?['full_name'],
      memberId: authUser.userMetadata?['member_id'],
      avatarUrl: authUser.userMetadata?['avatar_url'],
      role: authUser.userMetadata?['role'] ?? 'member',
      createdAt: DateTime.parse(authUser.createdAt),
      updatedAt: DateTime.parse(authUser.lastSignInAt ?? authUser.createdAt),
    );
  }

  // Get raw database data for debugging
  Future<List<Map<String, dynamic>>> getRawBooksData() async {
    try {
      print('🔍 Getting raw books data for debugging...');
      final response = await _client.from('books').select('*').limit(3);
      print('📊 Raw response type: ${response.runtimeType}');
      print('📊 Raw response: $response');
      
      if (response is List) {
        for (int i = 0; i < response.length; i++) {
          final item = response[i];
          print('📖 Item $i: $item');
          if (item is Map) {
            print('  Keys: ${item.keys.toList()}');
            print('  Title: ${item['title']}');
            print('  Author: ${item['author']}');
            print('  Subject ID: ${item['subject_id']}');
          }
        }
      }
      
      return response is List ? response.cast<Map<String, dynamic>>() : [];
    } catch (e) {
      print('❌ Error getting raw data: $e');
      return [];
    }
  }

  // Test database connection
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing Supabase connection...');
      final response = await _client.from('books').select('count').limit(1);
      print('✅ Database connection successful');
      return true;
    } catch (e) {
      print('❌ Database connection failed: $e');
      return false;
    }
  }

  // Check if books table has data
  Future<int> getBooksCount() async {
    try {
      print('📊 Getting books count...');
      final response = await _client.from('books').select('*');
      print('📈 Total books in database: ${response.length}');
      return response.length;
    } catch (e) {
      print('❌ Error getting books count: $e');
      return 0;
    }
  }

  // Book methods
  Future<List<Book>> getBooks({
    String? category,
    String? subject,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      print('🔍 Fetching books with filters: category=$category, subject=$subject, searchQuery=$searchQuery');
      
      // Join with subjects table to get subject name
      var query = _client
          .from('books')
          .select('''
            *,
            subjects(name)
          ''');

      if (category != null) {
        query = query.eq('category', category);
      }
      if (subject != null) {
        // Join with subjects table and filter by subject name
        query = query.eq('subjects.name', subject);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,author.ilike.%$searchQuery%');
      }
      final ordered = query.order('title');
      final limited = limit != null ? ordered.limit(limit) : ordered;
      final ranged = offset != null ? limited.range(offset, offset + (limit ?? 10) - 1) : limited;

      print('📚 Executing Supabase query...');
      final response = await ranged;
      print('✅ Raw response received: ${response.runtimeType}');
      print('📊 Response length: ${response is List ? response.length : 'Not a list'}');
      
      if (response is List) {
        print('📖 First few items: ${response.take(3).map((item) => item is Map ? item['title'] : 'Unknown').toList()}');
      }
      
      final books = (response as List).map((json) {
        try {
          // Add the subject name from the joined table
          final subjectData = json['subjects'] as Map<String, dynamic>?;
          final enrichedJson = <String, dynamic>{
            ...json as Map<String, dynamic>,
            'subject': subjectData?['name'] ?? 'Unknown',
          };
          return Book.fromJson(enrichedJson);
        } catch (e) {
          print('❌ Error parsing book: $e');
          print('📄 Raw JSON: $json');
          rethrow;
        }
      }).toList();
      
      print('🎉 Successfully parsed ${books.length} books');
      return books;
    } catch (e) {
      print('💥 Error in getBooks: $e');
      rethrow;
    }
  }

  Future<Book?> getBookById(String id) async {
    final response = await _client
        .from('books')
        .select('''
          *,
          subjects(name)
        ''')
        .eq('id', id)
        .single();
    
    if (response == null) return null;
    
    // Add the subject name from the joined table
    final subjectData = response['subjects'] as Map<String, dynamic>?;
    final enrichedJson = <String, dynamic>{
      ...response as Map<String, dynamic>,
      'subject': subjectData?['name'] ?? 'Unknown',
    };
    
    return Book.fromJson(enrichedJson);
  }

  Future<List<Book>> getBooksByCourse(String courseCode) async {
    final response = await _client
        .from('books')
        .select('''
          *,
          subjects(name)
        ''')
        .eq('course_code', courseCode)
        .order('title');
    
    return (response as List).map((json) {
      // Add the subject name from the joined table
      final subjectData = json['subjects'] as Map<String, dynamic>?;
      final enrichedJson = <String, dynamic>{
        ...json as Map<String, dynamic>,
        'subject': subjectData?['name'] ?? 'Unknown',
      };
      return Book.fromJson(enrichedJson);
    }).toList();
  }

  Future<List<String>> getSubjects({String? category}) async {
    try {
      print('🔍 Getting subjects with category filter: $category');
      
      // First, let's try to get subjects table if it exists
      var query = _client
          .from('subjects')
          .select('name');

      final response = await query.order('name');
      final subjects = (response as List)
          .map((json) => json['name'] as String)
          .toSet()
          .toList();
      
      print('✅ Found ${subjects.length} subjects from subjects table');
      return subjects;
    } catch (e) {
      print('⚠️ Subjects table not found or error: $e');
      print('📊 Returning hardcoded subjects list');
      
      // Return hardcoded subjects as fallback
      return [
        'Mathematics',
        'Science', 
        'Computer Science',
        'History',
        'Literature',
        'Self-Help',
        'Business',
        'Philosophy',
        'Psychology'
      ];
    }
  }

  // Admin-only: Import storage files as DB rows (requires RLS allowing inserts via authenticated role or run with service key server-side)
  Future<int> importBooksFromBucketToDb({String bucketName = 'book-files'}) async {
    final files = await _client.storage.from(bucketName).list();
    int imported = 0;
    for (final file in files) {
      final name = file.name;
      if (!(name.endsWith('.pdf') || name.endsWith('.epub') || name.endsWith('.mobi'))) {
        continue;
      }

      // Skip if already exists (by title and author parsed from filename)
      final fileName = name.replaceAll(RegExp(r'\.(pdf|epub|mobi)$'), '');
      final parts = fileName.split('_');
      final title = parts.isNotEmpty ? parts[0].replaceAll('-', ' ').trim() : fileName;
      final author = parts.length > 1 ? parts[1].replaceAll('-', ' ').trim() : 'Unknown Author';

      final existing = await _client
          .from('books')
          .select('id')
          .ilike('title', '%$title%')
          .maybeSingle();
      if (existing != null) {
        continue;
      }

      final fileUrl = _client.storage.from(bucketName).getPublicUrl(name);
      final nowIso = DateTime.now().toIso8601String();

      try {
        // Use security definer function if present to bypass RLS for authenticated role
        await _client.rpc('create_book_basic', params: {
          'p_id': const Uuid().v4(),
          'p_title': title,
          'p_author': author,
          'p_category': 'life',
          'p_book_file_url': fileUrl,
          'p_book_format': name.split('.').last,
          'p_file_size': file.metadata?['size'] ?? 0,
          'p_total_copies': 1,
          'p_available_copies': 1,
          'p_location': 'Digital Library',
        });
        imported += 1;
      } catch (_) {
        // Ignore individual failures
      }
    }
    return imported;
  }

  // Loan methods
  Future<List<Loan>> getUserLoans(String userId) async {
    final response = await _client
        .from('loans')
        .select('''
          *,
          books(title, author),
          users(full_name)
        ''')
        .eq('user_id', userId)
        .order('loan_date', ascending: false);

    return (response as List).map((json) {
      final bookData = json['books'] as Map<String, dynamic>?;
      final userData = json['users'] as Map<String, dynamic>?;
      
      return Loan.fromJson({
        ...json,
        'book_title': bookData?['title'],
        'book_author': bookData?['author'],
        'user_name': userData?['full_name'],
      });
    }).toList();
  }

  Future<Loan?> createLoan({
    required String userId,
    required String bookId,
    required DateTime dueDate,
  }) async {
    final response = await _client
        .from('loans')
        .insert({
          'user_id': userId,
          'book_id': bookId,
          'due_date': dueDate.toIso8601String(),
          'status': 'borrowed',
        })
        .select()
        .single();

    if (response == null) return null;
    return Loan.fromJson(response);
  }

  Future<bool> returnBook(String loanId) async {
    final response = await _client
        .from('loans')
        .update({
          'status': 'returned',
          'return_date': DateTime.now().toIso8601String(),
        })
        .eq('id', loanId)
        .select();

    return response != null;
  }

  // User profile methods
  Future<app_user.User?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
    
    if (response == null) return null;
    return app_user.User.fromJson(response);
  }

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select();

    return response != null;
  }

  // Book management methods
  Future<Book?> addBook({
    required String title,
    required String author,
    required String category,
    required String subjectName,
    String? isbn,
    String? courseCode,
    String? courseName,
    String? description,
    String? coverImageUrl,
    required int totalCopies,
    required String location,
    DateTime? publicationYear,
  }) async {
    try {
      print('📚 Adding new book: $title by $author');
      
      // First, get or create the subject
      String subjectId = await _getOrCreateSubject(subjectName);
      
      // Prepare book data
      final bookData = {
        'title': title,
        'author': author,
        'category': category,
        'subject_id': subjectId,
        'isbn': isbn,
        'course_code': courseCode,
        'course_name': courseName,
        'description': description,
        'cover_image_url': coverImageUrl,
        'total_copies': totalCopies,
        'available_copies': totalCopies, // Initially all copies are available
        'location': location,
        'publication_year': publicationYear?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('📖 Inserting book data: $bookData');
      
      // Insert the book
      final response = await _client
          .from('books')
          .insert(bookData)
          .select('''
            *,
            subjects(name)
          ''')
          .single();
      
      if (response == null) {
        print('❌ Failed to insert book');
        return null;
      }
      
      // Enrich with subject name
      final subjectData = response['subjects'] as Map<String, dynamic>?;
      final enrichedJson = <String, dynamic>{
        ...response as Map<String, dynamic>,
        'subject': subjectData?['name'] ?? 'Unknown',
      };
      
      final book = Book.fromJson(enrichedJson);
      print('✅ Successfully added book: ${book.title}');
      return book;
      
    } catch (e) {
      print('💥 Error adding book: $e');
      rethrow;
    }
  }

  Future<bool> updateBook(String bookId, Map<String, dynamic> updates) async {
    try {
      print('📚 Updating book: $bookId');
      
      // If updating subject, handle the subject_id mapping
      if (updates.containsKey('subject')) {
        final subjectName = updates['subject'] as String;
        final subjectId = await _getOrCreateSubject(subjectName);
        updates['subject_id'] = subjectId;
        updates.remove('subject'); // Remove the subject name, keep only subject_id
      }
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('books')
          .update(updates)
          .eq('id', bookId)
          .select();
      
      return response != null;
    } catch (e) {
      print('💥 Error updating book: $e');
      return false;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      print('🗑️ Deleting book: $bookId');
      
      final response = await _client
          .from('books')
          .delete()
          .eq('id', bookId);
      
      return response != null;
    } catch (e) {
      print('💥 Error deleting book: $e');
      return false;
    }
  }

  // Helper method to get or create subject
  Future<String> _getOrCreateSubject(String subjectName) async {
    try {
      // First try to find existing subject
      final existingSubject = await _client
          .from('subjects')
          .select('id')
          .eq('name', subjectName)
          .maybeSingle();
      
      if (existingSubject != null) {
        return existingSubject['id'] as String;
      }
      
      // Create new subject if it doesn't exist
      print('📝 Creating new subject: $subjectName');
      final newSubject = await _client
          .from('subjects')
          .insert({
            'name': subjectName,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      
      return newSubject['id'] as String;
    } catch (e) {
      print('⚠️ Error handling subject: $e');
      // Return a default subject ID or handle error appropriately
      return 'default-subject-id';
    }
  }

  // Test method to check bucket access with auth
  Future<void> testBucketAccessWithAuth() async {
    try {
      print('🧪 Testing bucket access with authentication...');
      
      final bucketName = 'book-files';
      
      // Check if user is authenticated
      final currentUser = _client.auth.currentUser;
      print('🔐 Current user: ${currentUser?.email ?? 'Not authenticated'}');
      
      // Test 1: Get bucket info
      try {
        final bucketInfo = await _client.storage.getBucket(bucketName);
        print('✅ Bucket info: ${bucketInfo.name}, public: ${bucketInfo.public}');
      } catch (e) {
        print('❌ Could not get bucket info: $e');
      }
      
      // Test 2: Try to list files with auth
      try {
        final files = await _client.storage.from(bucketName).list();
        print('📁 List files result: ${files.length} files');
        if (files.isNotEmpty) {
          print('📖 First file: ${files.first.name}');
          print('📖 File metadata: ${files.first.metadata}');
        }
      } catch (e) {
        print('❌ Could not list files: $e');
      }
      
      // Test 3: Try to access a specific file
      try {
        final testFile = 'As It Is in Heaven_ How Eternit - Greg Laurie.pdf';
        final fileUrl = _client.storage.from(bucketName).getPublicUrl(testFile);
        print('🔗 Test file URL: $fileUrl');
      } catch (e) {
        print('❌ Could not get file URL: $e');
      }
      
    } catch (e) {
      print('💥 Error testing bucket access with auth: $e');
    }
  }

  // Test method to check bucket access
  Future<void> testBucketAccess() async {
    try {
      print('🧪 Testing bucket access...');
      
      final bucketName = 'book-files';
      
      // Test 1: Get bucket info
      try {
        final bucketInfo = await _client.storage.getBucket(bucketName);
        print('✅ Bucket info: ${bucketInfo.name}, public: ${bucketInfo.public}');
      } catch (e) {
        print('❌ Could not get bucket info: $e');
      }
      
      // Test 2: Try to list files
      try {
        final files = await _client.storage.from(bucketName).list();
        print('📁 List files result: ${files.length} files');
        if (files.isNotEmpty) {
          print('📖 First file: ${files.first.name}');
        }
      } catch (e) {
        print('❌ Could not list files: $e');
      }
      
      // Test 3: Try to access a specific file
      try {
        final testFile = 'As It Is in Heaven_ How Eternit - Greg Laurie.pdf';
        final fileUrl = _client.storage.from(bucketName).getPublicUrl(testFile);
        print('🔗 Test file URL: $fileUrl');
      } catch (e) {
        print('❌ Could not get file URL: $e');
      }
      
    } catch (e) {
      print('💥 Error testing bucket access: $e');
    }
  }

  // Method to fetch books from your bucket
  Future<List<Book>> getBooksFromBucket() async {
    try {
      print('📚 Fetching books from bucket...');
      
      // List your bucket contents
      final bucketName = 'book-files'; // Your actual bucket name
      
      print('🔍 Attempting to list files from bucket: $bucketName');
      
      // First, let's check if we can access the bucket
      try {
        final bucketInfo = await _client.storage.getBucket(bucketName);
        print('✅ Bucket info: ${bucketInfo.name}, public: ${bucketInfo.public}');
      } catch (e) {
        print('⚠️ Could not get bucket info: $e');
      }
      
      final response = await _client.storage.from(bucketName).list();
      
      print('📁 Found ${response.length} files in bucket');
      print('🔍 Response type: ${response.runtimeType}');
      
      if (response.isNotEmpty) {
        print('📖 First few files: ${response.take(3).map((f) => f.name).toList()}');
      }
      
      final books = <Book>[];
      for (final file in response) {
        if (file.name.endsWith('.pdf') || file.name.endsWith('.epub') || file.name.endsWith('.mobi')) {
          // Generate a public URL for the file
          final fileUrl = _client.storage.from(bucketName).getPublicUrl(file.name);
          
          // Extract book info from filename (you can customize this)
          final fileName = file.name.replaceAll(RegExp(r'\.(pdf|epub|mobi)$'), '');
          final parts = fileName.split('_');
          
          final book = Book(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate unique ID
            title: parts.length > 0 ? parts[0].replaceAll('-', ' ') : fileName,
            author: parts.length > 1 ? parts[1].replaceAll('-', ' ') : 'Unknown Author',
            category: 'course', // Default category
            subject: 'General', // Default subject
            bookFileUrl: fileUrl,
            bookFormat: file.name.split('.').last,
            fileSize: file.metadata?['size'] ?? 0,
            totalCopies: 1,
            availableCopies: 1,
            location: 'Digital Library',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          books.add(book);
          print('📖 Added book: ${book.title} by ${book.author}');
        }
      }
      
      print('✅ Successfully loaded ${books.length} books from bucket');
      return books;
      
    } catch (e) {
      print('💥 Error fetching books from bucket: $e');
      print('🔍 Error details: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        print('🚨 This looks like a permissions issue!');
      }
      return [];
    }
  }

  // Method to upload a book file to bucket
  Future<String?> uploadBookToBucket({
    required String fileName,
    required Uint8List fileBytes,
    required String fileType, // 'application/pdf', 'application/epub+zip', etc.
  }) async {
    try {
      print('📤 Uploading book to bucket: $fileName');
      
      final bucketName = 'book-files';
      
      // Upload the file
      final response = await _client.storage
          .from(bucketName)
          .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
            contentType: fileType,
          ));
      
      if (response.isEmpty) {
        print('✅ Book uploaded successfully');
        
        // Get the public URL
        final fileUrl = _client.storage.from(bucketName).getPublicUrl(fileName);
        print('🔗 Public URL: $fileUrl');
        
        return fileUrl;
      } else {
        print('❌ Upload failed: $response');
        return null;
      }
      
    } catch (e) {
      print('💥 Error uploading book: $e');
      return null;
    }
  }

  // Real-time subscriptions
  Stream<List<Book>> subscribeToBooks() {
    return _client
        .from('books')
        .stream(primaryKey: ['id'])
        .map((response) => 
            (response as List).map((json) => Book.fromJson(json)).toList());
  }

  Stream<List<Loan>> subscribeToUserLoans(String userId) {
    return _client
        .from('loans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((response) => 
            (response as List).map((json) => Loan.fromJson(json)).toList());
  }

  // Update user profile information
  Future<bool> updateUser({String? fullName, String? email}) async {
    try {
      print('🔄 Updating user profile...');
      
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (email != null) updates['email'] = email;

      if (updates.isEmpty) {
        print('⚠️ No updates to make');
        return true;
      }

      // Update user metadata
      final response = await _client.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );

      if (response.user != null) {
        print('✅ User profile updated successfully');
        return true;
      } else {
        print('❌ Failed to update user profile');
        return false;
      }
      
    } catch (e) {
      print('💥 Error updating user profile: $e');
      return false;
    }
  }
}
