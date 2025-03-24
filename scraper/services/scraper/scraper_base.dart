import 'package:my_uz/utils/logger.dart';
import 'package:http/http.dart' as http;

/// Podstawowa klasa dla wszystkich scraperów
/// Zawiera wspólne metody i funkcje używane przez różne scrapery
class ScraperBase {
  /// Podstawowy URL dla wszystkich operacji scrapowania
  final String baseUrl = 'https://plan.uz.zgora.pl/';

  /// Klient HTTP używany do wykonywania żądań
  final http.Client client = http.Client();

  /// Pobiera zawartość strony HTML pod podanym URL
  Future<String> fetchPage(String url) async {
    try {
      Logger.info('Pobieranie strony: $url');
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Błąd pobierania strony. Kod statusu: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Błąd podczas pobierania strony: $e');
      rethrow;
    }
  }

  /// Wyodrębnia ID z URL na podstawie podanego prefiksu
  String? extractIdFromUrl(String url, String prefix) {
    final RegExp regex = RegExp('$prefix=([0-9]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Normalizuje URL - dodaje prefiks baseUrl jeśli URL nie zaczyna się od http
  String normalizeUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    } else if (url.startsWith('/')) {
      return baseUrl + url.substring(1);
    } else {
      return baseUrl + url;
    }
  }

  /// Wprowadza opóźnienie wykonania aby nie przeciążać serwera
  Future<void> delay([int milliseconds = 300]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Zwalnia zasoby używane przez scraper
  void dispose() {
    client.close();
  }
}