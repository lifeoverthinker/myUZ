import 'package:html/parser.dart' as parser;
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'scraper_base.dart';

class NauczycielScraper extends ScraperBase {
  NauczycielScraper();

  Future<List<Nauczyciel>> scrapeNauczyciele() async {
    Logger.info('Rozpoczęto pobieranie listy nauczycieli');

    final url = '${baseUrl}plan/lista_n.php';
    final html = await fetchPage(url);
    final document = parser.parse(html);

    final linki = document.querySelectorAll('a[href^="plan.php?"]');
    final nauczyciele = <Nauczyciel>[];

    for (final link in linki) {
      final href = link.attributes['href'] ?? '';
      final url = normalizeUrl(href);
      final nazwa = link.text.trim();

      if (nazwa.isEmpty || url.isEmpty) continue;

      final urlId = extractUrlId(url);

      nauczyciele.add(Nauczyciel(
        urlId: urlId,
        nazwa: nazwa,
        urlPlan: url,
      ));
    }

    Logger.info('Pobrano ${nauczyciele.length} nauczycieli');

    return nauczyciele;
  }

  String extractUrlId(String url) {
    return extractIdFromUrl(url, 'id') ?? '';
  }
}