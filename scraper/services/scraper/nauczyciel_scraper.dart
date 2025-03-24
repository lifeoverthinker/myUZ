import 'package:html/parser.dart' as parser;
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/wydzial.dart';
import 'package:my_uz/utils/logger.dart';
import './scraper_base.dart';

class NauczycielScraper extends ScraperBase {
  Future<List<Nauczyciel>> scrapeNauczycieleWydzialu(Wydzial wydzial) async {
    final html = await fetchPage(wydzial.url);
    final document = parser.parse(html);
    final List<Nauczyciel> nauczyciele = [];

    try {
      final rows = document.querySelectorAll('table.table-bordered tr:not(.gray)');

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 2) {
          final nameCell = cells[0];

          final link = nameCell.querySelector('a');
          if (link != null) {
            final fullName = link.text.trim();
            final href = link.attributes['href'];

            if (href != null) {
              final urlPlan = normalizeUrl(href);

              if (wydzial.id != null) {
                final nauczyciel = Nauczyciel(
                  pelneImieNazwisko: fullName,
                  email: '', // Email zostanie dodany później po pobraniu planu
                  wydzialId: wydzial.id!,
                  urlPlan: urlPlan,
                );

                nauczyciele.add(nauczyciel);
              }
            }
          }
        }
      }

      Logger.info('Znaleziono ${nauczyciele.length} nauczycieli w wydziale ${wydzial.nazwa}');
      return nauczyciele;
    } catch (e) {
      Logger.error('Błąd podczas scrapowania nauczycieli: $e');
      return [];
    }
  }
}