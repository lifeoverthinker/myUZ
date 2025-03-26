import 'package:html/parser.dart' as html;
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperNauczyciel {
  final HttpService _httpService;
  static const String _baseUrl = 'https://plan.uz.zgora.pl';
  static const String _nauczycielPath = '/nauczyciel.php';

  ScraperNauczyciel({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<Nauczyciel?> scrapeNauczyciel(String nauczycielId) async {
    Logger.info(
        'Rozpoczynam pobieranie danych nauczyciela o ID: $nauczycielId');

    try {
      final url = '$_baseUrl$_nauczycielPath?id_nauczyciel=$nauczycielId';
      Logger.debug('Pobieranie danych z: $url');

      final response = await _httpService.getBody(url);

      if (response.isEmpty) {
        Logger.error(
            'Otrzymano pustą odpowiedź przy próbie pobrania danych nauczyciela $nauczycielId');
        return null;
      }

      final document = html.parse(response);

      // Pobieramy imię i nazwisko z nagłówka
      final headerElements = document.querySelectorAll('h1');
      if (headerElements.isEmpty) {
        Logger.error(
            'Nie znaleziono nagłówka z imieniem i nazwiskiem nauczyciela $nauczycielId');
        return null;
      }

      final nazwa = headerElements.first.text.trim();

      // Parsowanie danych kontaktowych
      String? email;

      final tableElements = document.querySelectorAll('table.tabela');
      if (tableElements.isNotEmpty) {
        final rows = tableElements.first.querySelectorAll('tr');

        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length >= 2) {
            final label = cells[0].text.trim().toLowerCase();
            final value = cells[1].text.trim();

            if (label.contains('e-mail')) {
              email = value;
            }
            // Pozostałe dane (telefon, konsultacje, katedra) nie są zapisywane w bazie
          }
        }
      }

      // Walidacja email
      if (email != null) {
        if (email.isEmpty) {
          email = null;
        } else if (!email.contains('@')) {
          email = null;
        }
      }

      // Tworzymy obiekt nauczyciela
      Nauczyciel nauczyciel = Nauczyciel(
        id: 0,
        urlPlan: url,
        urlId: nauczycielId,
        nazwa: nazwa,
        email: email,
      );

      Logger.info(
          'Pomyślnie pobrano dane nauczyciela: ${nauczyciel.nazwa ?? "brak nazwy"}');
      return nauczyciel;
    } catch (e, stackTrace) {
      Logger.error(
          'Wystąpił błąd podczas pobierania danych nauczyciela $nauczycielId',
          e,
          stackTrace);
      rethrow;
    }
  }

  String? extractEmailFromText(String text) {
    final emailRegex =
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final match = emailRegex.firstMatch(text);
    return match?.group(0);
  }

  Future<bool> validateNauczycielData(Nauczyciel nauczyciel) async {
    Logger.debug(
        'Walidacja danych nauczyciela: ${nauczyciel.nazwa ?? "brak nazwy"}');

    final errors = <String>[];

    // Sprawdzenie nazwy
    final nazwa = nauczyciel.nazwa;
    if (nazwa == null || nazwa.isEmpty) {
      errors.add('Brak imienia i nazwiska');
    } else if (!nazwa.contains(' ')) {
      errors.add('Niepoprawny format imienia i nazwiska: $nazwa');
    }

    // Sprawdzenie email
    final email = nauczyciel.email;
    if (email != null && email.isNotEmpty) {
      final emailMatch =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
              .hasMatch(email);
      if (!emailMatch) {
        errors.add('Niepoprawny format adresu email: $email');
      }
    }

    if (errors.isNotEmpty) {
      Logger.warning(
          'Znaleziono problemy z danymi nauczyciela ${nauczyciel.nazwa ?? "brak nazwy"}: ${errors.join(', ')}');
      return false;
    }

    return true;
  }
}
