import 'package:logger/logger.dart';
import 'package:my_uz/services/scraper_service.dart';

void main() async {
  final logger = Logger();
  final scraper = ScraperService();

  try {
    await scraper.scrapujPlany();
    logger.i('✅ Scrapowanie zakończone pomyślnie');
  } catch (e) {
    logger.e('❌ Błąd podczas scrapowania', error: e);
  }
}