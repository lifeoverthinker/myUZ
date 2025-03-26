import '../scraper/services/scraper/scraper_kierunki.dart';
import '../scraper/services/scraper/scraper_grupy.dart';
import '../scraper/services/scraper/scraper_zajecia_grupy.dart';
import '../scraper/services/scraper/scraper_nauczyciel.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

Future<void> main() async {
  final startTime = DateTime.now();

  // Ustaw plik logowania
  final logFile = File('scraper_logs.txt');
  setupLogging(logFile);

  Logger.info(
      '=== Rozpoczęcie procesu scrapowania: ${startTime.toString()} ===');

  final supabaseService = SupabaseService();
  final checkpointFile = File('scraper_checkpoint.json');

  // Wczytaj punkt kontrolny, jeśli istnieje
  Map<String, dynamic> checkpoint = {};
  if (await checkpointFile.exists()) {
    try {
      checkpoint = json.decode(await checkpointFile.readAsString());
      Logger.info('Wczytano punkt kontrolny: ${checkpoint.toString()}');
    } catch (e) {
      Logger.warning('Nie udało się wczytać punktu kontrolnego: $e');
    }
  }

  try {
    // Test połączenia
    Logger.info('Sprawdzanie połączenia z bazą...');
    bool connectionOk = await withRetry(() => testConnection(supabaseService));
    if (!connectionOk) return;

    // Etap 1: Pobierz kierunki
    if (checkpoint['stage'] == null || checkpoint['stage'] < 1) {
      Logger.info('=== ETAP 1/4: Pobieranie kierunków ===');

      final kierunki = await withTimeout(() async {
        return await scrapeKierunki(supabaseService);
      }, Duration(minutes: 30));

      Logger.info('Pobrano ${kierunki.length} kierunków');

      if (kierunki.isEmpty) {
        Logger.error('Nie znaleziono kierunków!');
        return;
      }

      // Zapisz punkt kontrolny
      checkpoint['stage'] = 1;
      await saveCheckpoint(checkpointFile, checkpoint);
    } else {
      Logger.info('Pomijam ETAP 1 (już wykonany)');
    }

    // Etap 2: Pobierz grupy
    if (checkpoint['stage'] < 2) {
      Logger.info('=== ETAP 2/4: Pobieranie grup ===');
      final kierunki = await supabaseService.getAllKierunki();
      int grupyCount = 0;

      // Zacznij od ostatniego przetworzonego kierunku, jeśli istnieje
      int startIdx = 0;
      if (checkpoint['lastKierunekId'] != null) {
        startIdx =
            kierunki.indexWhere((k) => k.id == checkpoint['lastKierunekId']);
        if (startIdx != -1) {
          startIdx += 1; // Zacznij od następnego
        } else {
          startIdx = 0;
        }
      }

      // Przetwórz każdy kierunek z małym opóźnieniem, aby uniknąć ograniczeń częstotliwości
      for (int i = startIdx; i < kierunki.length; i++) {
        final kierunek = kierunki[i];
        Logger.info(
            'Przetwarzanie kierunku (${i + 1}/${kierunki.length}): ${kierunek.nazwa}');

        await withRetry(() => scrapeGrupy(kierunek, supabaseService));
        final grupy = await supabaseService.getGrupyByKierunekId(kierunek.id!);
        grupyCount += grupy.length;

        // Zapisz pośredni punkt kontrolny
        checkpoint['lastKierunekId'] = kierunek.id;
        await saveCheckpoint(checkpointFile, checkpoint);

        // Małe opóźnienie, aby uniknąć przeciążenia serwera
        await Future.delayed(const Duration(seconds: 3));
      }

      Logger.info('Łącznie pobrano $grupyCount grup');

      // Zapisz punkt kontrolny
      checkpoint['stage'] = 2;
      checkpoint.remove(
          'lastKierunekId'); // Resetuj, żeby nie przeszkadzało w następnych etapach
      await saveCheckpoint(checkpointFile, checkpoint);
    } else {
      Logger.info('Pomijam ETAP 2 (już wykonany)');
    }

    // Etap 3: Pobierz zajęcia
    if (checkpoint['stage'] < 3) {
      Logger.info('=== ETAP 3/4: Pobieranie zajęć dla grup ===');

      await withTimeout(() async {
        // Przekazujemy kopię checkpoint, aby funkcja mogła dodać swoje dane
        final stageCheckpoint = Map<String, dynamic>.from(checkpoint);
        await scrapeZajeciaGrupy(supabaseService, checkpoint: stageCheckpoint);

        // Aktualizuj główny checkpoint o zmienione wartości
        checkpoint.addAll(stageCheckpoint);
      }, Duration(minutes: 120));

      final zajeciaCount = await supabaseService.getZajeciaCount();
      Logger.info('Łącznie zapisano $zajeciaCount zajęć dla grup');

      // Zapisz punkt kontrolny
      checkpoint['stage'] = 3;
      // Usuń klucze specyficzne dla etapu 3
      checkpoint.remove('lastGrupaId');
      await saveCheckpoint(checkpointFile, checkpoint);
    } else {
      Logger.info('Pomijam ETAP 3 (już wykonany)');
    }

    // Etap 4: Pobierz plany nauczycieli
    if (checkpoint['stage'] < 4) {
      Logger.info('=== ETAP 4/4: Pobieranie planów nauczycieli ===');
      final nauczyciele = await supabaseService.getAllNauczyciele();
      if (nauczyciele.isEmpty) {
        Logger.warning('Nie znaleziono nauczycieli w bazie!');
      } else {
        await withTimeout(() async {
          // Przekazujemy kopię checkpoint, aby funkcja mogła dodać swoje dane
          final stageCheckpoint = Map<String, dynamic>.from(checkpoint);
          await scrapeNauczyciel(nauczyciele, supabaseService,
              checkpoint: stageCheckpoint);

          // Aktualizuj główny checkpoint o zmienione wartości
          checkpoint.addAll(stageCheckpoint);
        }, Duration(minutes: 120));
      }

      // Zapisz punkt kontrolny
      checkpoint['stage'] = 4;
      // Usuń klucze specyficzne dla etapu 4
      checkpoint.remove('lastNauczycielId');
      await saveCheckpoint(checkpointFile, checkpoint);
    } else {
      Logger.info('Pomijam ETAP 4 (już wykonany)');
    }

    // Usuń plik punktu kontrolnego po zakończeniu
    if (await checkpointFile.exists()) {
      await checkpointFile.delete();
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    Logger.info(
        '=== Zakończenie procesu: ${duration.inMinutes}m ${duration.inSeconds % 60}s ===');
  } catch (e, stack) {
    Logger.error('Krytyczny błąd: $e');
    Logger.error('Stack: $stack');

    // Nawet w przypadku błędu, zapisz nasz postęp
    await saveCheckpoint(checkpointFile, checkpoint);
  }
}

// Konfiguracja logowania do pliku
void setupLogging(File logFile) {
  if (!logFile.existsSync()) {
    logFile.createSync();
  }
  Logger.setLogFile(logFile);
}

// Pomocnicza funkcja do zapisywania checkpointu
Future<void> saveCheckpoint(File file, Map<String, dynamic> checkpoint) async {
  try {
    await file.writeAsString(json.encode(checkpoint));
    Logger.info('Zapisano punkt kontrolny: ${checkpoint.toString()}');
  } catch (e) {
    Logger.error('Błąd zapisu punktu kontrolnego: $e');
  }
}

// Funkcja pomocnicza do prób ponowienia
Future<T> withRetry<T>(Future<T> Function() operation,
    {int retries = 3, Duration delay = const Duration(seconds: 5)}) async {
  try {
    return await operation();
  } catch (e) {
    if (retries > 0) {
      Logger.warning(
          'Operacja nie powiodła się: $e. Ponawiam za ${delay.inSeconds}s. Pozostałe próby: ${retries - 1}');
      await Future.delayed(delay);
      return withRetry(operation, retries: retries - 1, delay: delay * 1.5);
    }
    rethrow;
  }
}

// Funkcja pomocnicza do obsługi timeoutów
Future<T> withTimeout<T>(
    Future<T> Function() operation, Duration timeout) async {
  return operation().timeout(timeout, onTimeout: () {
    Logger.error(
        'Przekroczono limit czasu dla operacji (${timeout.inMinutes}m)');
    throw TimeoutException('Operacja przekroczyła limit czasu');
  });
}

Future<bool> testConnection(SupabaseService supabaseService) async {
  try {
    final kierunki = await supabaseService.getAllKierunki();
    Logger.info(
        'Połączenie z bazą OK. Znaleziono ${kierunki.length} kierunków.');
    return true;
  } catch (e) {
    Logger.error('Błąd połączenia z bazą: $e');
    return false;
  }
}
