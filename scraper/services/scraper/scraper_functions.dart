import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

// WAŻNE: Te funkcje muszą być na najwyższym poziomie do działania z compute

// Funkcja do pobierania grup w izolacji
Future<List<Map<String, dynamic>>> fetchGrupyIsolate(Map<String, dynamic> data) async {
  final kierunekId = data['id'] as int;
  final kierunekUrl = data['url'] as String;
  final baseUrl = 'https://plan.uz.zgora.pl';

  try {
    // Pobierz HTML
    final response = await http.get(
      Uri.parse(kierunekUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/91.0.4472.124',
        'Accept': '*/*',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final html = response.body;
    final soup = BeautifulSoup(html);
    final allLinks = soup.findAll('a');

    // Najlepsze podejście: szukaj linków do planu
    var grupyLinks = allLinks.where((link) {
      try {
        final href = link.attributes['href'] ?? '';
        return href.contains('plan.php') || href.contains('ID=');
      } catch (_) {
        return false;
      }
    }).toList();

    // Jeśli nie znaleziono grupyLinks, szukaj po zawartości tekstu
    if (grupyLinks.isEmpty) {
      grupyLinks = allLinks.where((link) {
        try {
          final text = link.text.trim().toLowerCase();
          return text.contains('grupa') ||
              text.contains('gr.') ||
              RegExp(r'\d{1,3}[a-zA-Z]{1,3}').hasMatch(text);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    if (grupyLinks.isEmpty) {
      return [];
    }

    final grupy = <Map<String, dynamic>>[];

    for (final link in grupyLinks) {
      try {
        final nazwa = link.text.trim();
        final href = link.attributes['href'] ?? '';

        // Wyciągnij ID grupy z URL
        String groupId = _extractGroupIdFromUrl(href);

        if (groupId.isNotEmpty) {
          grupy.add({
            'nazwa': nazwa,
            'kierunek_id': kierunekId,
            'url_ics': '$baseUrl/grupy_ics.php?ID=$groupId&KIND=GG'
          });
        }
      } catch (_) {
        // Ignoruj błędy w pojedynczych linkach
      }
    }

    return grupy;
  } catch (_) {
    // Zwróć pustą listę w przypadku błędu
    return [];
  }
}

// Funkcja do pobierania zajęć w izolacji
Future<List<Map<String, dynamic>>> fetchZajeciaIsolate(Map<String, dynamic> data) async {
  final grupaId = data['id'] as int;
  final urlIcs = data['url_ics'] as String;

  try {
    // Pobierz ICS
    final response = await http.get(
      Uri.parse(urlIcs),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/91.0.4472.124',
        'Accept': '*/*',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final icsData = response.body;
    final calendar = ICalendar.fromString(icsData);

    final events = calendar.data.where((comp) =>
    comp.containsKey('type') &&
        comp['type'] == 'VEVENT').toList();

    final zajecia = <Map<String, dynamic>>[];

    for (final event in events) {
      try {
        final startDateProp = event['dtstart'];
        final endDateProp = event['dtend'];

        final startDate = startDateProp is IcsDateTime ?
        startDateProp.toDateTime() : null;
        final endDate = endDateProp is IcsDateTime ?
        endDateProp.toDateTime() : null;

        final summary = event['summary']?.toString() ?? '';
        final summaryParts = summary.split(':');
        final przedmiot = summaryParts.isNotEmpty ? summaryParts[0].trim() : 'Brak nazwy';
        final nauczyciel = summaryParts.length > 1 ? summaryParts[1].trim() : 'Brak danych';

        String rodzajZajec = 'Inne';
        if (event.containsKey('categories')) {
          final categories = event['categories'];
          if (categories is List && categories.isNotEmpty) {
            rodzajZajec = categories.first.toString();
          }
        }

        zajecia.add({
          'uid': event['uid']?.toString() ?? 'Brak UID',
          'grupa_id': grupaId,
          'Od': startDate?.toIso8601String(),
          'Do': endDate?.toIso8601String(),
          'Przedmiot': przedmiot,
          'RZ': rodzajZajec,
          'Nauczyciel': nauczyciel,
          'Miejsce': event['location']?.toString() ?? 'Brak sali',
          'Terminy': 'D'
        });
      } catch (_) {
        // Ignoruj błędy w pojedynczych wydarzeniach
      }
    }

    return zajecia;
  } catch (_) {
    // Zwróć pustą listę w przypadku błędu
    return [];
  }
}

// Pomocnicza funkcja do ekstrakcji ID grupy
String _extractGroupIdFromUrl(String href) {
  String groupId = '';

  try {
    // Metoda 1: Parsowanie parametrów URL
    final uri = Uri.parse(href);
    if (uri.queryParameters.containsKey('ID')) {
      groupId = uri.queryParameters['ID']!;
    } else if (uri.queryParameters.containsKey('ID_GRUPA')) {
      groupId = uri.queryParameters['ID_GRUPA']!;
    }

    // Metoda 2: Regex dla różnych formatów ID w URL
    if (groupId.isEmpty) {
      final regexPatterns = [
        RegExp(r'ID=(\d+)'),
        RegExp(r'ID_GRUPA=(\d+)'),
      ];

      for (final regex in regexPatterns) {
        final match = regex.firstMatch(href);
        if (match != null && match.groupCount >= 1) {
          groupId = match.group(1)!;
          break;
        }
      }
    }
  } catch (_) {
    // Ignoruj błędy wyciągania ID
  }

  return groupId;
}