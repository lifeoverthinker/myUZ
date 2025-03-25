import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

// Podstawowy URL
const baseUrl = 'https://plan.uz.zgora.pl';
final DateTime dataRozpoczecia = DateTime(2023, 10, 1);
final DateTime dataZakonczenia = DateTime(2024, 2, 15);

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
    await scrapeZajeciaForGrupy(supabaseService);

    final zajeciaCount = await supabaseService.getZajeciaCount();
    Logger.info('Lacznie zapisano $zajeciaCount zajec dla grup');

    // Pobierz plany nauczycieli
    Logger.info('=== ETAP 4/4: Pobieranie planow nauczycieli ===');
    final nauczyciele = await supabaseService.getAllNauczyciele();
    if (nauczyciele.isEmpty) {
      Logger.warning('Nie znaleziono nauczycieli w bazie!');
    } else {
      await scrapePlanyNauczycieli(nauczyciele, supabaseService);
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

Future<List<Kierunek>> scrapeKierunki(SupabaseService supabaseService) async {
  List<Kierunek> kierunki = [];

  try {
    final url = '$baseUrl/grupy_lista_kierunkow.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var links = document.querySelectorAll('a[href*="select_grupa.php"]');

      for (var link in links) {
        final linkUrl = link.attributes['href'];
        final nazwa = link.text.trim();

        if (linkUrl != null && nazwa.isNotEmpty) {
          final kierunekUrl =
              linkUrl.startsWith('http') ? linkUrl : '$baseUrl/$linkUrl';

          final kierunek = Kierunek(
            nazwa: nazwa,
            url: kierunekUrl,
          );

          final updatedKierunek =
              await supabaseService.createOrUpdateKierunek(kierunek);
          kierunki.add(updatedKierunek);
        }
      }
    } else {
      Logger.error(
          'Blad pobierania strony kierunkow. Kod: ${response.statusCode}');
    }
  } catch (e) {
    Logger.error('Blad podczas pobierania kierunkow: $e');
  }

  return kierunki;
}

Future<void> scrapeGrupy(
    Kierunek kierunek, SupabaseService supabaseService) async {
  try {
    final response = await http.get(Uri.parse(kierunek.url));

    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var links = document.querySelectorAll('a[href*="plan.php"]');

      for (var link in links) {
        final linkUrl = link.attributes['href'];
        final nazwa = link.text.trim();

        if (linkUrl != null && nazwa.isNotEmpty) {
          // Tworzymy URL do planu ICS (format eksportu kalendarza)
          final urlIcs =
              linkUrl.replaceFirst('plan.php', 'plany/plan_grupa.ics');
          final fullUrlIcs =
              urlIcs.startsWith('http') ? urlIcs : '$baseUrl/$urlIcs';

          final grupa = Grupa(
            nazwa: nazwa,
            kierunekId: kierunek.id!,
            urlIcs: fullUrlIcs,
          );

          await supabaseService.createOrUpdateGrupa(grupa);
        }
      }
    } else {
      Logger.error(
          'Blad pobierania grup dla kierunku ${kierunek.nazwa}. Kod: ${response.statusCode}');
    }
  } catch (e) {
    Logger.error('Blad podczas pobierania grup dla ${kierunek.nazwa}: $e');
  }
}

Future<void> scrapeZajeciaForGrupy(SupabaseService supabaseService) async {
  try {
    // Pobieramy wszystkie grupy z bazy
    final allGrupy = await supabaseService.getAllGrupy();
    Logger.info('Pobieranie zajec dla ${allGrupy.length} grup');

    for (var grupa in allGrupy) {
      Logger.info('Pobieranie zajec dla grupy ${grupa.nazwa}');

      // Konstruujemy URL do planu zajec (nie ICS)
      final planUrl =
          grupa.urlIcs.replaceAll('plany/plan_grupa.ics', 'plan.php');

      final response = await http.get(Uri.parse(planUrl));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var tables = document.querySelectorAll('table.TabPlan');

        if (tables.isNotEmpty) {
          var tableRows = tables.first.querySelectorAll('tr');
          List<Zajecia> zajeciaList = [];

          for (int i = 1; i < tableRows.length; i++) {
            var row = tableRows[i];
            var cells = row.querySelectorAll('td');

            if (cells.length > 1) {
              String godzina = cells[0].text.trim();

              for (int dzien = 1; dzien < cells.length; dzien++) {
                var cellContent = cells[dzien].text.trim();
                if (cellContent.isNotEmpty) {
                  final lines = cellContent.split('\n');
                  final przedmiot = lines.isNotEmpty ? lines[0].trim() : '';
                  final rodzaj = lines.length > 1 ? lines[1].trim() : '';
                  final nauczycielNazwa =
                      lines.length > 2 ? lines[2].trim() : '';
                  final miejsce = lines.length > 3 ? lines[3].trim() : '';

                  // Tworzenie unikalnego ID
                  final zajeciaId = '${grupa.id}_${dzien}_${godzina}_$przedmiot'
                      .hashCode
                      .toString();

                  // Dodanie nauczyciela do bazy
                  Nauczyciel? nauczyciel;
                  int? nauczycielId;
                  if (nauczycielNazwa.isNotEmpty) {
                    nauczyciel = Nauczyciel(
                      nazwa: nauczycielNazwa,
                      urlPlan:
                          '$baseUrl/nauczyciel.php?nauczyciel=${Uri.encodeComponent(nauczycielNazwa)}',
                    );
                    nauczyciel = await supabaseService
                        .createOrUpdateNauczyciel(nauczyciel);
                    nauczycielId = nauczyciel.id;
                  }

                  // Termin zajec: dzien tygodnia i godzina
                  final terminy = "${dzienTygodnia(dzien)}, $godzina";

                  final zajecia = Zajecia(
                    uid: zajeciaId,
                    grupaId: grupa.id,
                    od: dataRozpoczecia,
                    do_: dataZakonczenia,
                    przedmiot: przedmiot,
                    rz: rodzaj,
                    miejsce: miejsce,
                    terminy: terminy,
                    nauczycielId: nauczycielId,
                  );

                  zajeciaList.add(zajecia);
                }
              }
            }
          }

          // Usuwamy stare zajecia dla grupy
          if (zajeciaList.isNotEmpty) {
            await supabaseService.deleteZajeciaForGrupa(grupa.id!);
            await supabaseService.batchInsertZajecia(zajeciaList);
            Logger.info(
                'Dodano ${zajeciaList.length} zajec dla grupy ${grupa.nazwa}');
          } else {
            Logger.warning('Nie znaleziono zajec dla grupy ${grupa.nazwa}');
          }
        } else {
          Logger.warning(
              'Nie znaleziono tabeli z planem dla grupy ${grupa.nazwa}');
        }
      } else {
        Logger.error(
            'Blad pobierania planu dla grupy ${grupa.nazwa}. Kod: ${response.statusCode}');
      }
    }
  } catch (e, stack) {
    Logger.error('Blad podczas pobierania zajec dla grup: $e');
    Logger.error('Stack trace: $stack');
  }
}

String dzienTygodnia(int dzien) {
  switch (dzien) {
    case 1:
      return 'Poniedzialek';
    case 2:
      return 'Wtorek';
    case 3:
      return 'Sroda';
    case 4:
      return 'Czwartek';
    case 5:
      return 'Piatek';
    default:
      return 'Nieznany';
  }
}

Future<void> scrapePlanyNauczycieli(
    List<Nauczyciel> nauczyciele, SupabaseService supabaseService) async {
  try {
    Logger.info('Rozpoczeto aktualizacje planow nauczycieli');

    for (var nauczyciel in nauczyciele) {
      if (nauczyciel.nazwa?.isEmpty ?? true) {
        Logger.warning('Pomijanie nauczyciela z pusta nazwa');
        continue;
      }

      Logger.info('Pobieranie planu dla nauczyciela: ${nauczyciel.nazwa}');

      final response = await http.get(Uri.parse(nauczyciel.urlPlan));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var tables = document.querySelectorAll('table.TabPlan');
        List<PlanNauczyciela> plany = [];

        if (tables.isNotEmpty) {
          var tableRows = tables.first.querySelectorAll('tr');

          for (int i = 1; i < tableRows.length; i++) {
            var row = tableRows[i];
            var cells = row.querySelectorAll('td');

            if (cells.length > 1) {
              String godzina = cells[0].text.trim();

              for (int dzien = 1; dzien < cells.length; dzien++) {
                var cellContent = cells[dzien].text.trim();
                if (cellContent.isNotEmpty) {
                  final lines = cellContent.split('\n');
                  final przedmiot = lines.isNotEmpty ? lines[0].trim() : '';
                  final rodzaj = lines.length > 1 ? lines[1].trim() : '';
                  // Usunięto lub wykorzystano zmienną grupyInfo
                  final miejsce = lines.length > 3 ? lines[3].trim() : '';

                  // Tworzenie unikalnego ID dla zajec nauczyciela
                  final planId =
                      '${nauczyciel.id}_${dzien}_${godzina}_$przedmiot'
                          .hashCode
                          .toString();

                  // Termin zajec: dzien tygodnia i godzina
                  final terminy = "${dzienTygodnia(dzien)}, $godzina";

                  final plan = PlanNauczyciela(
                    uid: planId,
                    nauczycielId: nauczyciel.id!,
                    od: dataRozpoczecia,
                    do_: dataZakonczenia,
                    przedmiot: przedmiot,
                    rz: rodzaj,
                    miejsce: miejsce,
                    terminy: terminy,
                  );

                  plany.add(plan);
                }
              }
            }
          }

          if (plany.isNotEmpty) {
            await supabaseService.deleteZajeciaForNauczyciel(nauczyciel.id!);
            await supabaseService.batchInsertPlanNauczyciela(plany);
            Logger.info(
                'Dodano ${plany.length} zajec dla nauczyciela ${nauczyciel.nazwa}');
          } else {
            Logger.warning(
                'Nie znaleziono planu dla nauczyciela ${nauczyciel.nazwa}');
          }
        } else {
          Logger.warning(
              'Nie znaleziono tabeli z planem dla nauczyciela ${nauczyciel.nazwa}');
        }
      } else {
        Logger.error(
            'Blad pobierania planu dla nauczyciela ${nauczyciel.nazwa}. Kod: ${response.statusCode}');
      }
    }

    Logger.info('Zakonczono aktualizacje planow nauczycieli');
  } catch (e, stack) {
    Logger.error('Blad podczas pobierania planow nauczycieli: $e');
    Logger.error('Stack trace: $stack');
  }
}
