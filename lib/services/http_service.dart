import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_uz/utils/logger.dart';

class HttpService {
  final http.Client _client;
  final int maxRetries;
  final Duration retryDelay;
  final Duration timeout;

  HttpService({
    http.Client? client,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  // Metoda do wykonywania zapytania GET i pobierania ciała odpowiedzi
  Future<String> getBody(String url) async {
    Logger.debug('HTTP GET: $url');
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final response = await _client.get(Uri.parse(url)).timeout(timeout);

        if (response.statusCode == 200) {
          Logger.debug('Otrzymano odpowiedź HTTP 200 OK (${response.contentLength} bajtów)');
          return response.body;
        } else {
          final error = 'Błąd HTTP ${response.statusCode}: ${response.reasonPhrase}';
          Logger.error(error);

          if (_shouldRetry(response.statusCode) && attempts < maxRetries - 1) {
            attempts++;
            await Future.delayed(retryDelay);
            continue;
          }

          throw Exception(error);
        }
      } catch (e, stackTrace) {
        if (attempts < maxRetries - 1) {
          Logger.warning('Ponawiam próbę po błędzie', e);
          attempts++;
          await Future.delayed(retryDelay);
        } else {
          Logger.error('Błąd podczas wykonywania zapytania HTTP', e, stackTrace);
          rethrow;
        }
      }
    }

    throw Exception('Przekroczono maksymalną liczbę prób');
  }

  bool _shouldRetry(int statusCode) {
    return statusCode >= 500 || statusCode == 429;
  }

  // Metoda do wykonywania zapytania GET i dekodowania odpowiedzi JSON
  Future<Map<String, dynamic>> getJson(String url) async {
    final body = await getBody(url);

    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas dekodowania JSON', e, stackTrace);
      rethrow;
    }
  }

  // Metoda do wykonywania zapytania POST
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    Logger.debug('HTTP POST: $url');

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? json.encode(body) : null,
      ).timeout(timeout);

      Logger.debug('POST odpowiedź: ${response.statusCode}');
      return response;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas wykonywania zapytania POST', e, stackTrace);
      rethrow;
    }
  }

  // Metoda do zamykania klienta HTTP
  void dispose() {
    _client.close();
  }
}