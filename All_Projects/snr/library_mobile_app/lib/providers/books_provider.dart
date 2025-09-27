import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import '../models/book.dart';
import '../services/supabase_service.dart';
import '../services/cover_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BooksProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  late final StreamSubscription<AuthState> _authSubscription;

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  List<String> _subjects = [];
  List<String> _courseSubjects = [];
  List<String> _lifeSubjects = [];

  bool _isLoading = false;
  String? _error;
  String _currentCategory = 'all';
  String _currentSubject = 'all';
  String _searchQuery = '';

  // Getters
  List<Book> get books => _books;
  List<Book> get filteredBooks => _filteredBooks;
  List<String> get subjects => _subjects;
  List<String> get courseSubjects => _courseSubjects;
  List<String> get lifeSubjects => _lifeSubjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;
  String get currentSubject => _currentSubject;
  String get searchQuery => _searchQuery;

  BooksProvider() {
    _initializeAndLoad();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        print('🔐 BooksProvider: Auth state changed -> ${event.name}. Reloading books from DB...');
        await _loadBooks();
      } else if (event == AuthChangeEvent.signedOut) {
        print('🔐 BooksProvider: Signed out. Clearing books.');
        _books = [];
        _filteredBooks = [];
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    print('🚀 BooksProvider: Initializing...');
    // Load books first for faster UX; run diagnostics in background
    await _loadBooks();
    // Subjects can load in parallel after books are visible
    // ignore: unawaited_futures
    _loadSubjects();
    // Background diagnostics for logs only
    // ignore: unawaited_futures
    _logDbState();
  }

  Future<void> _loadBooks() async {
    try {
      print('🔄 BooksProvider: Starting to load books...');
      _setLoading(true);
      _error = null;
      
      // First try to load from database
      print('📚 BooksProvider: Trying to load books from database...');
      List<Book> books = [];
      
      try {
        books = await _supabaseService.getBooks();
        print('✅ BooksProvider: Received ${books.length} books from database');
        if (books.isEmpty) {
          print('⚠️ BooksProvider: Database returned 0 books, trying bucket...');
          books = await _supabaseService.getBooksFromBucket();
          print('📚 BooksProvider: Received ${books.length} books from bucket');
        }
      } catch (e) {
        print('⚠️ BooksProvider: Error loading from database, trying bucket...');
        // If database call errors, try to load from bucket
        books = await _supabaseService.getBooksFromBucket();
        print('📚 BooksProvider: Received ${books.length} books from bucket');
      }
      
      // Show books immediately
      _books = books;
      print('📖 BooksProvider: Stored ${_books.length} books in _books');
      
      _applyFilters();
      print('🔍 BooksProvider: Applied filters, filtered books: ${_filteredBooks.length}');
      
      _setLoading(false);
      if (_books.isEmpty) {
        _setError('No books available yet');
        print('ℹ️ BooksProvider: No books available from DB or bucket');
      } else {
        print('🎉 BooksProvider: Books loading completed successfully');
      }

      // Enrich missing covers in background so UI doesn't block
      // ignore: unawaited_futures
      _enrichMissingCoversAsync();
    } catch (e) {
      print('💥 BooksProvider: Error loading books: $e');
      _setError('Failed to load books: $e');
      _setLoading(false);
    }
  }

  Future<void> _enrichMissingCoversAsync() async {
    final coverService = CoverService();
    final indices = <int>[];
    for (var i = 0; i < _books.length; i++) {
      final b = _books[i];
      if (b.coverImageUrl == null || b.coverImageUrl!.isEmpty) {
        indices.add(i);
      }
    }
    if (indices.isEmpty) return;

    const int maxConcurrent = 5;
    for (var start = 0; start < indices.length; start += maxConcurrent) {
      final batch = indices.skip(start).take(maxConcurrent).toList();
      final futures = batch.map((idx) async {
        final b = _books[idx];
        final url = await coverService.findCoverUrl(
          isbn: b.isbn,
          title: _sanitizeTitle(b.title),
          author: _sanitizeAuthor(b.author),
        );
        if (url != null && url.isNotEmpty) {
          _books[idx] = b.copyWith(coverImageUrl: url);
        }
      });
      await Future.wait(futures);
      // Notify after each batch so covers appear progressively
      _applyFilters();
    }
  }

  String _sanitizeTitle(String title) {
    var t = title;
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r'\(.*?z[- ]?lib.*?\)', caseSensitive: false), '').trim();
    t = t.replaceAll(RegExp(r'\(Z[- ]?Library\)', caseSensitive: false), '').trim();
    return t;
  }

  String _sanitizeAuthor(String author) {
    var a = author;
    a = a.replaceAll(RegExp(r'\s+'), ' ').trim();
    return a;
  }

  Future<void> _logDbState() async {
    try {
      final isConnected = await _supabaseService.testConnection();
      if (!isConnected) {
        print('⚠️ BooksProvider: Database connection test failed (logs only).');
        return;
      }
      final count = await _supabaseService.getBooksCount();
      print('📊 BooksProvider (diag): DB books count = $count');
      final raw = await _supabaseService.getRawBooksData();
      print('🔍 BooksProvider (diag): raw sample size = ${raw.length}');
    } catch (_) {}
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _supabaseService.getSubjects();
      _subjects = subjects;
      
      // Separate subjects by category
      _courseSubjects = subjects.where((subject) => 
        ['Mathematics', 'Science', 'Computer Science', 'History', 'Literature'].contains(subject)
      ).toList();
      
      _lifeSubjects = subjects.where((subject) => 
        ['Self-Help', 'Business', 'Philosophy', 'Psychology'].contains(subject)
      ).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  void _applyFilters() {
    print('🔍 BooksProvider: Applying filters...');
    print('📊 Current state: category=$_currentCategory, subject=$_currentSubject, searchQuery=$_searchQuery');
    print('📚 Total books before filtering: ${_books.length}');
    
    _filteredBooks = _books.where((book) {
      // Category filter
      if (_currentCategory != 'all' && book.category != _currentCategory) {
        return false;
      }
      
      // Subject filter
      if (_currentSubject != 'all' && book.subject != _currentSubject) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               book.subject.toLowerCase().contains(query) ||
               (book.courseName?.toLowerCase().contains(query) ?? false) ||
               (book.isbn?.toLowerCase().contains(query) ?? false);
      }
      
      return true;
    }).toList();
    
    print('🎯 Final filtered books count: ${_filteredBooks.length}');
    notifyListeners();
  }

  void setCategory(String category) {
    _currentCategory = category;
    _applyFilters();
  }

  void setSubject(String subject) {
    _currentSubject = subject;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearFilters() {
    _currentCategory = 'all';
    _currentSubject = 'all';
    _searchQuery = '';
    _applyFilters();
  }

  Future<List<Book>> getBooksByCourse(String courseCode) async {
    try {
      return await _supabaseService.getBooksByCourse(courseCode);
    } catch (e) {
      _setError('Failed to load course books: $e');
      return [];
    }
  }

  Future<List<Book>> getBooksBySubject(String subject) async {
    try {
      return _books.where((book) => book.subject == subject).toList();
    } catch (e) {
      _setError('Failed to load subject books: $e');
      return [];
    }
  }

  List<Book> getAvailableBooks() {
    return _books.where((book) => book.isAvailable).toList();
  }

  List<Book> getOverdueBooks() {
    // This would typically come from loans data
    return [];
  }

  Future<void> refreshBooks() async {
    await _loadBooks();
  }

  Future<int> importFromBucketToDb() async {
    try {
      _setLoading(true);
      final count = await _supabaseService.importBooksFromBucketToDb();
      await _loadBooks();
      _setLoading(false);
      return count;
    } catch (e) {
      _setLoading(false);
      _setError('Import failed: $e');
      return 0;
    }
  }

  // Test bucket access with auth
  Future<void> testBucketAccessWithAuth() async {
    try {
      print('🧪 BooksProvider: Testing bucket access with authentication...');
      await _supabaseService.testBucketAccessWithAuth();
    } catch (e) {
      print('💥 BooksProvider: Error testing bucket access with auth: $e');
    }
  }

  // Test bucket access
  Future<void> testBucketAccess() async {
    try {
      print('🧪 BooksProvider: Testing bucket access...');
      await _supabaseService.testBucketAccess();
    } catch (e) {
      print('💥 BooksProvider: Error testing bucket access: $e');
    }
  }

  // Load books specifically from bucket
  Future<void> loadBooksFromBucket() async {
    try {
      _setLoading(true);
      _error = null;
      
      print('📚 BooksProvider: Loading books from bucket...');
      final books = await _supabaseService.getBooksFromBucket();
      
      _books = books;
      _applyFilters();
      
      _setLoading(false);
      print('✅ BooksProvider: Loaded ${books.length} books from bucket');
      
    } catch (e) {
      _setError('Failed to load books from bucket: $e');
      _setLoading(false);
    }
  }

  // Upload book file to bucket
  Future<bool> uploadBookFile({
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      print('📤 BooksProvider: Uploading book file...');
      final fileUrl = await _supabaseService.uploadBookToBucket(
        fileName: fileName,
        fileBytes: fileBytes,
        fileType: fileType,
      );
      
      if (fileUrl != null) {
        // Refresh the books list to show the new book
        await loadBooksFromBucket();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to upload book file');
        _setLoading(false);
        return false;
      }
      
    } catch (e) {
      _setError('Error uploading book file: $e');
      _setLoading(false);
      return false;
    }
  }

  // Book management methods
  Future<bool> addBook({
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
      _setLoading(true);
      _error = null;
      
      final newBook = await _supabaseService.addBook(
        title: title,
        author: author,
        category: category,
        subjectName: subjectName,
        isbn: isbn,
        courseCode: courseCode,
        courseName: courseName,
        description: description,
        coverImageUrl: coverImageUrl,
        totalCopies: totalCopies,
        location: location,
        publicationYear: publicationYear,
      );
      
      if (newBook != null) {
        // Add the new book to the list and refresh
        await _loadBooks();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to add book');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error adding book: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBook(String bookId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _error = null;
      
      final success = await _supabaseService.updateBook(bookId, updates);
      
      if (success) {
        // Refresh the books list
        await _loadBooks();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update book');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating book: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      _setLoading(true);
      _error = null;
      
      final success = await _supabaseService.deleteBook(bookId);
      
      if (success) {
        // Refresh the books list
        await _loadBooks();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete book');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting book: $e');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Debug method to check book data
  void debugPrintBooks() {
    print('Total books: ${_books.length}');
    for (int i = 0; i < _books.length && i < 3; i++) {
      final book = _books[i];
      print('Book ${i + 1}: ${book.title}');
      print('  Cover URL: ${book.coverImageUrl ?? 'No cover'}');
      print('  Category: ${book.category}');
      print('  Subject: ${book.subject}');
    }
  }

  // Test backend service directly
  Future<void> testBackendService() async {
    try {
      print('🧪 Testing Backend Service...');
      
      // Test 1: Add a sample book
      print('\n📚 Test 1: Adding a sample book...');
      final newBook = await _supabaseService.addBook(
        title: 'Flutter Development Guide',
        author: 'John Smith',
        category: 'course',
        subjectName: 'Computer Science',
        isbn: '978-1234567890',
        courseCode: 'CS101',
        courseName: 'Introduction to Programming',
        description: 'A comprehensive guide to Flutter development',
        coverImageUrl: 'https://example.com/flutter-cover.jpg',
        totalCopies: 3,
        location: 'A1-B3',
        publicationYear: DateTime(2024),
      );
      
      if (newBook != null) {
        print('✅ Sample book added successfully: ${newBook.title}');
      } else {
        print('❌ Failed to add sample book');
      }
      
      // Test 2: Get books count
      print('\n📊 Test 2: Getting books count...');
      final count = await _supabaseService.getBooksCount();
      print('📈 Total books in database: $count');
      
      // Test 3: Get raw data
      print('\n🔍 Test 3: Getting raw data...');
      final rawData = await _supabaseService.getRawBooksData();
      print('📖 Raw data items: ${rawData.length}');
      
      // Test 4: Get subjects
      print('\n📚 Test 4: Getting subjects...');
      final subjects = await _supabaseService.getSubjects();
      print('📝 Available subjects: $subjects');
      
      // Test 5: Refresh books list
      print('\n🔄 Test 5: Refreshing books list...');
      await _loadBooks();
      print('📚 Books loaded: ${_books.length}');
      
      print('\n🎉 Backend service test completed!');
      
    } catch (e) {
      print('💥 Error testing backend service: $e');
    }
  }
}
