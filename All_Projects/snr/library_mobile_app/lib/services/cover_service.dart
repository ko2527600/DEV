import 'dart:convert';
import 'package:http/http.dart' as http;

class CoverService {
  static final CoverService _instance = CoverService._internal();
  factory CoverService() => _instance;
  CoverService._internal();

  final Map<String, String?> _cache = {};

  Future<String?> findCoverUrl({String? isbn, String? title, String? author}) async {
    final key = _buildCacheKey(isbn: isbn, title: title, author: author);
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final query = _buildQuery(isbn: isbn, title: title, author: author);
      if (query.isEmpty) {
        _cache[key] = null;
        return null;
      }

      // Primary: Google Books
      final uri = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
          final imageLinks = volumeInfo?['imageLinks'] as Map<String, dynamic>?;
          final thumbnail = imageLinks?['thumbnail'] as String? ?? imageLinks?['smallThumbnail'] as String?;
          if (thumbnail != null && thumbnail.isNotEmpty) {
            final secure = thumbnail.startsWith('http://') ? thumbnail.replaceFirst('http://', 'https://') : thumbnail;
            _cache[key] = secure;
            return secure;
          }
        }
      }

      // Fallback: OpenLibrary covers
      final olTitle = title != null ? Uri.encodeComponent(title) : '';
      final olAuthor = author != null ? Uri.encodeComponent(author) : '';
      final olQuery = 'https://openlibrary.org/search.json?title=$olTitle&author=$olAuthor&limit=1';
      final olResp = await http.get(Uri.parse(olQuery)).timeout(const Duration(seconds: 5));
      if (olResp.statusCode == 200) {
        final data = json.decode(olResp.body) as Map<String, dynamic>;
        final docs = data['docs'] as List<dynamic>?;
        if (docs != null && docs.isNotEmpty) {
          final doc = docs.first as Map<String, dynamic>;
          final coverId = doc['cover_i'];
          if (coverId != null) {
            final url = 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
            _cache[key] = url;
            return url;
          }
        }
      }

      _cache[key] = null;
      return null;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }

  String _buildCacheKey({String? isbn, String? title, String? author}) {
    return [isbn ?? '', title?.toLowerCase() ?? '', author?.toLowerCase() ?? ''].join('|');
  }

  String _buildQuery({String? isbn, String? title, String? author}) {
    if (isbn != null && isbn.isNotEmpty) {
      return 'isbn:$isbn';
    }
    final parts = <String>[];
    if (title != null && title.isNotEmpty) {
      parts.add('intitle:${Uri.encodeComponent(title)}');
    }
    if (author != null && author.isNotEmpty) {
      parts.add('inauthor:${Uri.encodeComponent(author)}');
    }
    return parts.join('+');
  }
}


