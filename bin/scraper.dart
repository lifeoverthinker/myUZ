import '../scraper/services/scraper/scraper_kierunki.dart';
import '../scraper/services/scraper/scraper_grupy.dart';
import '../scraper/services/scraper/scraper_zajecia_grupy.dart';
import '../scraper/services/scraper/scraper_nauczyciel.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

Future<void> main() async {
  final startTime = DateTime.now();
  Logger.info(
      '=== Rozpoczecie procesu scrapowania: ${startTime.toString()} ===');

  final supabaseService = SupabaseService();

  try {
    // Test polaczenia
    Logger.info('Sprawdzanie polaczenia z baza...');
    bool connectionOk = await testConnection(supabaseService);
    if (!connectionOk) return;

    // Pobierz kierunki
    Logger.info('=== ETAP 1/4: Pobieranie kierunkow ===');
    final kierunki = await scrapeKierunki(supabaseService);
    Logger.info('Pobrano ${kierunki.length} kierunkow');

    if (kierunki.isEmpty) {
      Logger.error('Nie znaleziono kierunkow!');
      return;
    }

    // Pobierz grupy
    Logger.info('=== ETAP 2/4: Pobieranie grup ===');
    int grupyCount = 0;
    for (final kierunek in kierunki) {
      await scrapeGrupy(kierunek, supabaseService);
      final grupy = await supabaseService.getGrupyByKierunekId(kierunek.id!);
      grupyCount += grupy.length;
    }
    Logger.info('Lacznie pobrano $grupyCount grup');

    // Pobierz zajecia
    Logger.info('=== ETAP 3/4: Pobieranie zajec dla grup ===');
    await scrapeZajeciaGrupy(supabaseService);

    final zajeciaCount = await supabaseService.getZajeciaCount();
    Logger.info('Lacznie zapisano $zajeciaCount zajec dla grup');

    // Pobierz plany nauczycieli
    Logger.info('=== ETAP 4/4: Pobieranie planow nauczycieli ===');
    final nauczyciele = await supabaseService.getAllNauczyciele();
    if (nauczyciele.isEmpty) {
      Logger.warning('Nie znaleziono nauczycieli w bazie!');
    } else {
      await scrapeNauczyciel(nauczyciele, supabaseService);
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.info(
        '=== Zakonczenie procesu: ${duration.inMinutes}m ${duration.inSeconds % 60}s ===');
  } catch (e, stack) {
    Logger.error('Krytyczny blad: $e');
    Logger.error('Stack: $stack');
  }
}

Future<bool> testConnection(SupabaseService supabaseService) async {
  try {
    final kierunki = await supabaseService.getAllKierunki();
    Logger.info(
        'Polaczenie z baza OK. Znaleziono ${kierunki.length} kierunkow.');
    return true;
  } catch (e) {
    Logger.error('Blad polaczenia z baza: $e');
    return false;
  }
}