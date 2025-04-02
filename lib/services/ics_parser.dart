import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:my_uz/models/zajecia_model.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

class IcsParser {
  final _logger = Logger();
  final _uuid = const Uuid();

  List<Zajecia> parsujIcs(String icsContent,
      {int? grupaId, int? nauczycielId}) {
    if (grupaId == null && nauczycielId == null) {
      throw ArgumentError('Musisz podać albo grupaId albo nauczycielId');
    }

    try {
      final iCalendar = ICalendar.fromString(icsContent);
      final events = iCalendar.data;
      final zajecia = <Zajecia>[];

      for (final event in events) {
        try {
          // Wyciągamy potrzebne dane
          final uid = event['uid'] ?? _uuid.v4();
          final summary = event['summary']?.toString() ?? '';
          // Usunięto linię z description - była nieużywana
          final location = event['location']?.toString() ?? '';

          // Parsowanie dat - bezpieczne konwersje z obsługą null
          DateTime? startDt = event['dtstart']?['dt'];
          DateTime? endDt = event['dtend']?['dt'];

          // Sprawdzenie czy daty są poprawne
          if (startDt == null || endDt == null) {
            _logger.w('Pominięto wydarzenie: brak wymaganych dat');
            continue;
          }

          // Teraz możemy bezpiecznie użyć tych dat, bo już sprawdziliśmy null
          final terminy = _formatujTermin(startDt, endDt);

          zajecia.add(Zajecia(
            uid: uid,
            grupaId: grupaId,
            nauczycielId: nauczycielId,
            od: startDt,
            do_: endDt,
            przedmiot: summary,
            miejsce: location,
            terminy: terminy,
          ));
        } catch (e) {
          _logger.e('Błąd podczas parsowania wydarzenia ICS: $e');
        }
      }

      return zajecia;
    } catch (e) {
      _logger.e('Błąd podczas parsowania pliku ICS: $e');
      return [];
    }
  }

  String _formatujTermin(DateTime start, DateTime koniec) {
    final dzien = _getDzienTygodnia(start);
    final godzinaStart =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final godzinaKoniec =
        '${koniec.hour.toString().padLeft(2, '0')}:${koniec.minute.toString().padLeft(2, '0')}';

    return '$dzien $godzinaStart-$godzinaKoniec';
  }

  String _getDzienTygodnia(DateTime data) {
    final dni = [
      'niedziela',
      'poniedziałek',
      'wtorek',
      'środa',
      'czwartek',
      'piątek',
      'sobota'
    ];
    return dni[data.weekday % 7];
  }
}
