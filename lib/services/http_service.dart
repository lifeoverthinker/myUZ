import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HttpService {
  static final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/91.0.4472.124',
    'Accept': '*/*',
  };

  // Cache dla pobranych URL
  static final Map<String, String> _cache = {};

  static Future<String?> fetch(String url, {bool useCache = true}) async {
    try {
      // Sprawdź cache jeśli włączony
      if (useCache && _cache.containsKey(url)) {
        debugPrint('HttpService: Zwracanie z cache: $url');
        return _cache[url];
      }

      debugPrint('HttpService: Pobieranie: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('HttpService: Pobrano pomyślnie (${response.contentLength} bajtów)');

        // Zapisz do cache
        if (useCache) {
          _cache[url] = response.body;
        }

        return response.body;
      } else {
        debugPrint('HttpService: Błąd HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('HttpService: Wyjątek: $e');
      return null;
    }
  }

  // Czyszczenie cache
  static void clearCache() {
    _cache.clear();
    debugPrint('HttpService: Cache wyczyszczony');
  }
}