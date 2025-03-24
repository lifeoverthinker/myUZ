import 'dart:async';
import 'package:html/parser.dart' as parser;
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'scraper_base.dart';

class PlanNauczycielaScraper extends ScraperBase {
  Future<List<PlanNauczyciela>> scrapePlanNauczyciela(
      Nauczyciel nauczyciel) async {
    final html = await fetchPage(nauczyciel.urlPlan);
    final document = parser.parse(html);
    final List<PlanNauczyciela> plany = [];

    try {
      // Najpierw sprawdź, czy jest email
      final emailLink = document.querySelector('h4 a[href^="mailto:"]');
      if (emailLink != null) {
        final href = emailLink.attributes['href'];
        if (href != null && href.startsWith('mailto:')) {
          final email = href.substring(7); // Usuń przedrostek mailto:

          // Aktualizuj nauczyciela z adresem email
          final updatedNauczyciel = Nauczyciel(
            id: nauczyciel.id,
            pelneImieNazwisko: nauczyciel.pelneImieNazwisko,
            email: email,
            wydzialId: nauczyciel.wydzialId,
            urlPlan: nauczyciel.urlPlan,
          );

          await SupabaseService.createOrUpdateNauczyciel(updatedNauczyciel);
          Logger.info('Zaktualizowano email nauczyciela: $email');
        }
      }

      // Pobierz tabelę z planem
      final table = document.querySelector('#table_groups');
      if (table != null) {
        final rows = table.querySelectorAll('tr:not(.gray)');

        for (var row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length >= 7) {
            // Od, Do, Przedmiot, RZ, Grupy, Miejsce, Terminy
            final odText = cells[0].text.trim();
            final doText = cells[1].text.trim();
            final przedmiot = cells[2].text.trim();

            final rzElement = cells[3].querySelector('label');
            final rz = rzElement?.text.trim();

            final miejsceLink = cells[5].querySelector('a');
            final miejsce = miejsceLink != null
                ? miejsceLink.text.trim()
                : cells[5].text.trim();

            final terminyLink = cells[6].querySelector('a');
            final terminy = terminyLink != null
                ? terminyLink.text.trim()
                : cells[6].text.trim();

            // Parsowanie czasów
            final od = _parseTimeString(odText);
            final do_ = _parseTimeString(doText);

            if (od != null && do_ != null && nauczyciel.id != null) {
              final uniqueContent =
                  '${nauczyciel.id}-$odText-$doText-$przedmiot-$miejsce';
              final uid = _generateUid(uniqueContent);

              final plan = PlanNauczyciela(
                uid: uid,
                nauczycielId: nauczyciel.id!,
                od: od,
                do_: do_,
                przedmiot: przedmiot,
                rz: rz,
                miejsce: miejsce,
                terminy: terminy,
              );

              plany.add(plan);
            }
          }
        }

        // Zapisz plany do bazy danych
        if (plany.isNotEmpty && nauczyciel.id != null) {
          // Najpierw usuń stare plany
          await SupabaseService.deleteZajeciaForNauczyciel(nauczyciel.id!);
          // Następnie dodaj nowe
          await SupabaseService.batchInsertPlanNauczyciela(plany);
          Logger.info(
              'Pobrano szczegóły nauczyciela: ${nauczyciel.pelneImieNazwisko} (${nauczyciel.email})');
        }
      }

      return plany;
    } catch (e) {
      Logger.error('Błąd podczas scrapowania planu nauczyciela: $e');
      return [];
    }
  }

  // Parsowanie czasu w formacie "HH:MM"
  DateTime? _parseTimeString(String timeStr) {
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
    return null;
  }

  // Generowanie unikalnego ID
  String _generateUid(String content) {
    var bytes = utf8.encode(content);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
