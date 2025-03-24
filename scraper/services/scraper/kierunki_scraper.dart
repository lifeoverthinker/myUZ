import 'package:html/parser.dart' as parser;
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/utils/logger.dart';
import './scraper_base.dart';

class KierunkiScraper extends ScraperBase {
  Future<List<Kierunek>> scrapeKierunki() async {
    final url = '${baseUrl}grupy_lista_kierunkow.php'; // Poprawiony URL
    final html = await fetchPage(url);
    final document = parser.parse(html);
    final List<Kierunek> kierunki = [];

    try {
      // Szukamy wszystkich linków do kierunków
      final kierunkiLinks = document
          .querySelectorAll('a[href^="grupy_lista_grup_kierunkow.php"]');

      for (var link in kierunkiLinks) {
        final nazwa = link.text.trim();
        final href = link.attributes['href'];

        if (href != null && nazwa.isNotEmpty) {
          final urlKierunek = normalizeUrl(href);

          final kierunek = Kierunek(
            nazwa: nazwa,
            url: urlKierunek,
          );

          kierunki.add(kierunek);
        }
      }

      Logger.info('Znaleziono ${kierunki.length} kierunków');
      return kierunki;
    } catch (e) {
      Logger.error('Błąd podczas scrapowania kierunków: $e');
      return [];
    }
  }
}
