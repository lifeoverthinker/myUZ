import 'package:html/parser.dart' as parser;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import './scraper_base.dart';

class GrupyScraper extends ScraperBase {
  Future<List<Grupa>> scrapeGrupy(Kierunek kierunek) async {
    final html = await fetchPage(kierunek.url);
    final document = parser.parse(html);
    final List<Grupa> grupy = [];

    try {
      // Pobierz tabelę z grupami
      final rows = document.querySelectorAll('table.table-bordered tr');

      for (var row in rows) {
        final link = row.querySelector('a[href*="grupy_plan.php"]');
        if (link != null) {
          final nazwa = link.text.trim();
          final href = link.attributes['href'];

          if (href != null && nazwa.isNotEmpty) {
            final planUrl = normalizeUrl(href);

            // Pobranie URL do kalendarza ICS
            final icsUrl = await _scrapeIcsUrl(planUrl);

            if (icsUrl != null && kierunek.id != null) {
              final grupa = Grupa(
                nazwa: nazwa,
                kierunekId: kierunek.id!,
                urlIcs: icsUrl,
              );

              grupy.add(grupa);

              // Zapisz grupę do bazy danych
              await SupabaseService.createOrUpdateGrupa(grupa);
            }
          }
        }
      }

      Logger.info('Znaleziono ${grupy.length} grup dla kierunku ${kierunek.nazwa}');
      return grupy;
    } catch (e) {
      Logger.error('Błąd podczas scrapowania grup: $e');
      return [];
    }
  }

  // Pobranie URL do pliku ICS dla grupy
  Future<String?> _scrapeIcsUrl(String planUrl) async {
    try {
      final html = await fetchPage(planUrl);
      final document = parser.parse(html);

      // Szukamy linku do ICS (Google lub Microsoft)
      final icsLinks = document.querySelectorAll('a[href*="grupy_ics.php"]');

      for (var link in icsLinks) {
        final href = link.attributes['href'];
        if (href != null && (href.contains('KIND=GG') || href.contains('KIND=MS'))) {
          return href;
        }
      }

      return null;
    } catch (e) {
      Logger.error('Błąd podczas pobierania URL ICS: $e');
      return null;
    }
  }
}