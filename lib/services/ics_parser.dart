import '../models/zajecia_model.dart';

class IcsParser {
  /// Główna metoda parsująca plik ICS
  static List<Zajecia> parsujZajecia(String icsContent, {int? grupaId}) {
    final List<Zajecia> listaZajec = [];
    final linie = icsContent.split('\n'); // Dzielimy plik na linie
    Map<String, String> aktualneZajecia = {}; // Tymczasowe przechowywanie danych

    for (var linia in linie) {
      linia = linia.trim(); // Usuwamy białe znaki

      // Rozpoczęcie nowych zajęć
      if (linia == 'BEGIN:VEVENT') {
        aktualneZajecia = {};
      }
      // Zakończenie zajęć - zapisujemy do listy
      else if (linia == 'END:VEVENT') {
        final zajecia = _stworzObiektZajec(aktualneZajecia, grupaId);
        listaZajec.add(zajecia);
      }
      // Parsowanie poszczególnych pól
      else if (aktualneZajecia.isNotEmpty) {
        final podzial = linia.split(':');
        if (podzial.length > 1) {
          final klucz = podzial[0];
          final wartosc = podzial.sublist(1).join(':');
          aktualneZajecia[klucz] = wartosc;
        }
      }
    }

    return listaZajec;
  }

  /// Tworzy obiekt Zajecia na podstawie mapy danych
  static Zajecia _stworzObiektZajec(Map<String, String> dane, int? grupaId) {
    // Parsowanie nazwy przedmiotu i nauczyciela
    final podzialNazwy = (dane['SUMMARY'] ?? 'Brak nazwy').split(':');
    final przedmiot = podzialNazwy.first.trim();
    final nauczyciel = podzialNazwy.length > 1 ? podzialNazwy.last.trim() : 'Brak danych';

    return Zajecia(
      uid: dane['UID'] ?? 'brak_uid_${DateTime.now().millisecondsSinceEpoch}',
      grupaId: grupaId,
      od: _parsujDate(dane['DTSTART'] ?? ''),
      do_: _parsujDate(dane['DTEND'] ?? ''),
      przedmiot: przedmiot,
      rz: dane['CATEGORIES'] ?? 'Ć', // Domyślnie ćwiczenia
      miejsce: dane['LOCATION'] ?? 'Brak sali',
      nauczyciel: nauczyciel,
    );
  }

  /// Konwertuje datę z formatu ICS na DateTime
  static DateTime _parsujDate(String dataICS) {
    try {
      if (dataICS.length >= 15) {
        // Format: 20250402T104000 -> 2025-04-02 10:40:00
        return DateTime.parse(
            dataICS
                .replaceFirstMapped(
                RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$'),
                    (match) => '${match[1]}-${match[2]}-${match[3]} ${match[4]}:${match[5]}:${match[6]}'
            )
        );
      }
      return DateTime.now(); // Domyślna data jeśli parsowanie się nie uda
    } catch (e) {
      return DateTime.now(); // Domyślna data w przypadku błędu
    }
  }
}