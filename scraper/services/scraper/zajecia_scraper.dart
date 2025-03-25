import 'dart:async';
import 'package:html/parser.dart' as parser;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'scraper_base.dart';

class ZajeciaScraper extends ScraperBase {
  final SupabaseService supabaseService;

  ZajeciaScraper(this.supabaseService);

  Future<List<Zajecia>> scrapeZajecia(Grupa grupa) async {
    final idMatch = RegExp(r'ID=(\d+)').firstMatch(grupa.urlIcs);

    if (idMatch == null) {
      Logger.error('Nie można wyodrębnić ID grupy z URL: ${grupa.urlIcs}');
      return [];
    }

    final groupId = idMatch.group(1);
    final planUrl = '${baseUrl}grupy_plan.php?ID=$groupId';

    final html = await fetchPage(planUrl);
    final document = parser.parse(html);
    final List<Zajecia> zajecia = [];

    try {
      // Pobierz tabelę z zajęciami
      final table = document.querySelector('#table_groups');
      if (table != null) {
        final rows = table.querySelectorAll('tr:not(.gray)');

        for (var row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length >= 8) {
            // PG, Od, Do, Przedmiot, RZ, Nauczyciel, Miejsce, Terminy
            // Pomijamy komórkę PG (index 0)
            final odText = cells[1].text.trim();
            final doText = cells[2].text.trim();
            final przedmiot = cells[3].text.trim();

            final rzElement = cells[4].querySelector('label');
            final rz = rzElement?.text.trim();

            final nauczycielCell = cells[5];
            final nauczycielLink = nauczycielCell.querySelector('a');
            int? nauczycielId;

            if (nauczycielLink != null) {
              final href = nauczycielLink.attributes['href'];
              if (href != null) {
                final urlPlan = normalizeUrl(href);
                final nauczyciel =
                    await supabaseService.getNauczycielByUrlPlan(urlPlan);
                nauczycielId = nauczyciel?.id;
              }
            }

            final miejsceLink = cells[6].querySelector('a');
            final miejsce = miejsceLink != null
                ? miejsceLink.text.trim()
                : cells[6].text.trim();
            final miejsceText = miejsce.isEmpty ? "Brak sali" : miejsce;

            final terminyLink = cells[7].querySelector('a');
            final terminy = terminyLink != null
                ? terminyLink.text.trim()
                : cells[7].text.trim();

            // Parsowanie czasów
            final od = _parseTimeString(odText);
            final do_ = _parseTimeString(doText);

            if (grupa.id != null) {
              final uniqueContent =
                  '${grupa.id}-$odText-$doText-$przedmiot-$miejsce';
              final uid = _generateUid(uniqueContent);

              final zajecie = Zajecia(
                uid: uid,
                grupaId: grupa.id!,
                od: od,
                // Używamy przekonwertowanej daty
                do_: do_,
                // Używamy przekonwertowanej daty
                przedmiot: przedmiot,
                rz: rz,
                miejsce: miejsceText,
                terminy: terminy,
                nauczycielId: nauczycielId,
              );

              zajecia.add(zajecie);
            }
          }
        }

        // Zapisz zajęcia do bazy danych
        if (zajecia.isNotEmpty && grupa.id != null) {
          // Najpierw usuń stare zajęcia
          await supabaseService.deleteZajeciaForGrupa(grupa.id!);
          // Następnie dodaj nowe
          await supabaseService.batchInsertZajecia(zajecia);
          Logger.info(
              'Zapisano ${zajecia.length} zajęć dla grupy ${grupa.nazwa}');
        }
      }

      return zajecia;
    } catch (e) {
      Logger.error('Błąd podczas scrapowania zajęć: $e');
      return [];
    }
  }

  // Parsowanie czasu w formacie "HH:MM"
  DateTime _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Używamy dzisiejszej daty jako bazy
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      Logger.error('Błąd parsowania czasu: $timeStr - $e');
    }

    // Domyślna data w przypadku błędu
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Generowanie unikalnego ID
  String _generateUid(String content) {
    var bytes = utf8.encode(content);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
