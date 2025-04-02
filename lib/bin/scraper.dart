import 'package:logger/logger.dart';
import 'package:my_uz/services/scraper_service.dart';

void main() async {
  final logger = Logger();
  final scraper = ScraperService();

  try {
    logger.i('🚀 Rozpoczęcie scrapowania planów zajęć');
    await scraper.scrapujPlany();
    logger.i('🎉 Pomyślnie zakończono scrapowanie');
  } catch (e) {
    logger.e('💥 Krytyczny błąd podczas scrapowania', error: e);
  }
}