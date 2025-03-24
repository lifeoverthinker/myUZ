import 'package:html/parser.dart' as parser;
  import 'package:my_uz/models/wydzial.dart';
  import 'package:my_uz/utils/logger.dart';
  import 'package:my_uz/services/db/supabase_service.dart'; // Dodany brakujący import
  import 'scraper_base.dart';

  class WydzialScraper extends ScraperBase {
    Future<List<Wydzial>> scrapeWydzialy() async {
      final url = '${baseUrl}nauczyciel_lista_wydzialow.php';
      final html = await fetchPage(url);
      final document = parser.parse(html);
      final List<Wydzial> wydzialy = [];

      try {
        final rows = document.querySelectorAll('table.table-bordered tr:not(.gray)');

        for (var row in rows) {
          final link = row.querySelector('a');
          if (link != null) {
            final nazwa = link.text.trim();
            final href = link.attributes['href'];

            if (href != null) {
              final fullUrl = normalizeUrl(href);

              final wydzial = Wydzial(
                nazwa: nazwa,
                url: fullUrl,
              );

              wydzialy.add(wydzial);
            }
          }
        }

        Logger.info('Znaleziono ${wydzialy.length} wydziałów');
        return wydzialy;
      } catch (e) {
        Logger.error('Błąd podczas scrapowania wydziałów: $e');
        return [];
      }
    }

    // Jeśli potrzebujesz statycznej metody do zapisu wydziałów do bazy danych
    static Future<void> saveToDatabase(List<Wydzial> wydzialy) async {
      for (var wydzial in wydzialy) {
        await SupabaseService.createOrUpdateWydzial(wydzial);
      }
    }
  }