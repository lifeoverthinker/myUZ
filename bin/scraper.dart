import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

const baseUrl = 'https://plan.uz.zgora.pl/grupy_lista_kierunkow.php';

Future<void> main() async {
  // Inicjalizacja serwisu
  final supabaseService = SupabaseService();

  // Pobierz kierunki
  final kierunki = await scrapeKierunki(supabaseService);

  // Pobierz grupy dla każdego kierunku
  for (final kierunek in kierunki) {
    await scrapeGrupy(kierunek, supabaseService);
  }

  // Pobierz zajęcia dla każdej grupy
  await scrapeZajeciaForGrupy(supabaseService);

  // Pobierz plany nauczycieli
  final nauczyciele = await supabaseService.getAllNauczyciele();
  await scrapePlanyNauczycieli(nauczyciele, supabaseService);
}

Future<List<Kierunek>> scrapeKierunki(SupabaseService supabaseService) async {
  List<Kierunek> kierunki = [];

  try {
    final response = await http.get(Uri.parse('$baseUrl/timetable2/'));
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var links = document.querySelectorAll('a.list-group-item');

      for (var link in links) {
        final url = link.attributes['href'];
        final nazwa = link.text.trim();

        if (url != null && url.contains('select_grupa.php')) {
          final kierunek = Kierunek(
            nazwa: nazwa,
            url: '$baseUrl/timetable2/$url',
          );

          final updatedKierunek =
              await supabaseService.createOrUpdateKierunek(kierunek);
          kierunki.add(updatedKierunek);
        }
      }
    }
  } catch (e) {
    Logger.error('Błąd podczas pobierania kierunków: $e');
  }

  // Jeśli nie znaleziono kierunków, pobierz z bazy
  if (kierunki.isEmpty) {
    kierunki = await supabaseService.getAllKierunki();
  }

  return kierunki;
}

Future<void> scrapeGrupy(
    Kierunek kierunek, SupabaseService supabaseService) async {
  try {
    final response = await http.get(Uri.parse(kierunek.url));
    if (response.statusCode == 200) {
      Logger.info('Pobrano stronę grup dla kierunku: ${kierunek.nazwa}');
      var document = parser.parse(response.body);

      // Znajdujemy linki w tabeli TR TD a
      var links = document.querySelectorAll('table.table-bordered tr td a');

      for (var link in links) {
        final url = link.attributes['href'];
        final nazwa = link.text.trim();

        if (url != null && url.contains('grupy_plan.php?ID=')) {
          final idMatch = RegExp(r'ID=(\d+)').firstMatch(url);
          if (idMatch != null) {
            final id = idMatch.group(1)!;

            // Tworzymy poprawny URL do pliku ICS
            final urlIcs = '$baseUrl/grupy_ics.php?ID=$id&KIND=MS';

            final grupa = Grupa(
              nazwa: nazwa,
              kierunekId: kierunek.id,
              urlIcs: urlIcs,
            );

            Logger.info('Znaleziono grupę: $nazwa, URL ICS: $urlIcs');
            await supabaseService.createOrUpdateGrupa(grupa);
          }
        }
      }
    } else {
      Logger.error('Nie można pobrać strony grup: ${response.statusCode}');
    }
  } catch (e) {
    Logger.error('Błąd podczas pobierania grup: $e');
  }
}

Future<void> scrapeZajeciaForGrupy(SupabaseService supabaseService) async {
  final kierunki = await supabaseService.getAllKierunki();

  for (final kierunek in kierunki) {
    final grupy = await supabaseService.getGrupyByKierunekId(kierunek.id!);

    for (final grupa in grupy) {
      await scrapeZajecia(grupa, supabaseService);
    }
  }
}

Future<void> scrapeZajecia(Grupa grupa, SupabaseService supabaseService) async {
  try {
    final response = await http.get(Uri.parse(grupa.urlIcs));
    if (response.statusCode == 200) {
      // Najpierw usuń stare zajęcia
      await supabaseService.deleteZajeciaForGrupa(grupa.id!);

      // Teraz przetwórz nowe zajęcia
      final icsContent = response.body;
      final List<Zajecia> zajeciaList = [];

      final regex = RegExp(r'BEGIN:VEVENT(.*?)END:VEVENT', dotAll: true);
      final matches = regex.allMatches(icsContent);

      for (final match in matches) {
        final eventContent = match.group(1)!;

        // Pobierz nauczyciela
        final nauczycielMatch =
            RegExp(r'DESCRIPTION:(.*?)\n').firstMatch(eventContent);
        String? nauczycielUrlId;
        int? nauczycielId;

        if (nauczycielMatch != null) {
          final description = nauczycielMatch.group(1);
          if (description != null && description.contains('http')) {
            final urlIdMatch = RegExp(r'id=([^&]+)').firstMatch(description);
            nauczycielUrlId = urlIdMatch?.group(1);

            if (nauczycielUrlId != null) {
              final nauczyciel =
                  await supabaseService.getNauczycielByUrlId(nauczycielUrlId);

              if (nauczyciel != null) {
                nauczycielId = nauczyciel.id;
              } else {
                final newNauczyciel =
                    await supabaseService.createOrUpdateNauczyciel(Nauczyciel(
                  urlId: nauczycielUrlId,
                  urlPlan:
                      '$baseUrl/timetable2/teacher_view.php?id=$nauczycielUrlId',
                ));
                nauczycielId = newNauczyciel.id;
              }
            }
          }
        }

        // Pobierz przedmiot
        final przedmiotMatch =
            RegExp(r'SUMMARY:(.*?)\n').firstMatch(eventContent);
        final przedmiot = przedmiotMatch?.group(1) ?? 'Nieznany przedmiot';

        // Pobierz czas
        final dtStartMatch =
            RegExp(r'DTSTART:(.*?)\n').firstMatch(eventContent);
        final dtEndMatch = RegExp(r'DTEND:(.*?)\n').firstMatch(eventContent);

        if (dtStartMatch != null && dtEndMatch != null) {
          final dtStart = dtStartMatch.group(1)!;
          final dtEnd = dtEndMatch.group(1)!;

          // Format: YYYYMMDDTHHmmssZ
          final startDateTime = parseIcsDateTime(dtStart);
          final endDateTime = parseIcsDateTime(dtEnd);

          if (startDateTime != null && endDateTime != null) {
            // Pobierz miejsce
            final locationMatch =
                RegExp(r'LOCATION:(.*?)\n').firstMatch(eventContent);
            final miejsce = locationMatch?.group(1);

            // Pobierz rodzaj zajęć (W, Ć, L...)
            final match = RegExp(r'\b([WĆLPSćwlps])\b').firstMatch(przedmiot);
            final rz = match?.group(1);

            // Generuj UID
            final contentToHash =
                '${grupa.id}-$przedmiot-$startDateTime-$endDateTime-$miejsce';
            final uid = _generateUid(contentToHash);

            // Utwórz obiekt Zajecia
            final zajecia = Zajecia(
              uid: uid,
              grupaId: grupa.id,
              nauczycielId: nauczycielId,
              od: startDateTime,
              do_: endDateTime,
              przedmiot: przedmiot,
              rz: rz,
              miejsce: miejsce,
            );

            zajeciaList.add(zajecia);
          }
        }
      }

      // Zapisz zajęcia do bazy danych
      if (zajeciaList.isNotEmpty) {
        await supabaseService.batchInsertZajecia(zajeciaList);
      }
    }
  } catch (e) {
    Logger.error('Błąd podczas pobierania zajęć dla grupy ${grupa.nazwa}: $e');
  }
}

DateTime? parseIcsDateTime(String icsDateTime) {
  try {
    // Format: YYYYMMDDTHHmmssZ
    final year = int.parse(icsDateTime.substring(0, 4));
    final month = int.parse(icsDateTime.substring(4, 6));
    final day = int.parse(icsDateTime.substring(6, 8));
    final hour = int.parse(icsDateTime.substring(9, 11));
    final minute = int.parse(icsDateTime.substring(11, 13));
    final second = int.parse(icsDateTime.substring(13, 15));

    return DateTime.utc(year, month, day, hour, minute, second);
  } catch (e) {
    Logger.error('Błąd parsowania daty ICS: $icsDateTime - $e');
    return null;
  }
}

String _generateUid(String content) {
  final bytes = utf8.encode(content);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<void> scrapePlanyNauczycieli(
    List<Nauczyciel> nauczyciele, SupabaseService supabaseService) async {
  Logger.info('Rozpoczęto aktualizację planów nauczycieli');
  int count = 0;

  for (final nauczyciel in nauczyciele) {
    await scrapePlanNauczyciela(nauczyciel, supabaseService);
    count++;

    if (count % 10 == 0) {
      Logger.info(
          'Zaktualizowano plany $count/${nauczyciele.length} nauczycieli');
    }
  }

  Logger.info('Zakończono aktualizację planów nauczycieli');
}

Future<void> scrapePlanNauczyciela(
    Nauczyciel nauczyciel, SupabaseService supabaseService) async {
  try {
    final response = await http.get(Uri.parse(nauczyciel.urlPlan));
    if (response.statusCode == 200) {
      Logger.info('Pobrano plan nauczyciela: ${nauczyciel.nazwa ?? nauczyciel.id}');

      // Najpierw usuń stare zajęcia
      await supabaseService.deleteZajeciaForNauczyciel(nauczyciel.id!);

      // Parsuj stronę HTML
      final document = parser.parse(response.body);
      final rows = document.querySelectorAll('#table_groups tr:not(.gray):not(:first-child)');
      final List<PlanNauczyciela> planyList = [];

      // Znajdź adres ICS dla Microsoft/Zimbra
      final icsLink = document.querySelector('a[href*="nauczyciel_ics.php"][id="idMS"]');
      final urlIcs = icsLink?.attributes['href'];

      if (urlIcs != null) {
        Logger.info('Znaleziono link ICS: $urlIcs dla nauczyciela ${nauczyciel.nazwa ?? nauczyciel.id}');
      }

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 7) {
          try {
            final odText = cells[0].text.trim();
            final doText = cells[1].text.trim();
            final przedmiot = cells[2].text.trim();
            final rzText = cells[3].querySelector('.rz')?.text.trim() ?? '';
            final miejsce = cells[5].text.trim().replaceAll('\n', ' ');
            final terminy = cells[6].text.trim();

            // Parsowanie dnia tygodnia z nagłówka
            String? dzienTygodnia;
            var headerRow = row.previousElementSibling;
            while (headerRow != null) {
              if (headerRow.classes.contains('gray') &&
                  headerRow.id.startsWith('label_day')) {
                dzienTygodnia = headerRow.text.trim();
                break;
              }
              headerRow = headerRow.previousElementSibling;
            }

            // Przekształcenie godzin na DateTime
            final currentDate = DateTime.now();
            int dayOffset = 0;

            // Ustalenie dnia tygodnia
            if (dzienTygodnia?.contains('Poniedziałek') == true) {
              dayOffset = 1 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Wtorek') == true) {
              dayOffset = 2 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Środa') == true) {
              dayOffset = 3 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Czwartek') == true) {
              dayOffset = 4 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Piątek') == true) {
              dayOffset = 5 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Sobota') == true) {
              dayOffset = 6 - currentDate.weekday;
            } else if (dzienTygodnia?.contains('Niedziela') == true) {
              dayOffset = 7 - currentDate.weekday;
            }

            // Jeśli dayOffset jest ujemny, przechodzimy do następnego tygodnia
            if (dayOffset < 0) {
              dayOffset += 7;
            }

            // Data zajęć
            final dataZajec = currentDate.add(Duration(days: dayOffset));

            // Parsowanie godzin
            final odParts = odText.split(':');
            final doParts = doText.split(':');

            if (odParts.length == 2 && doParts.length == 2) {
              final odGodzina = int.parse(odParts[0]);
              final odMinuta = int.parse(odParts[1]);
              final doGodzina = int.parse(doParts[0]);
              final doMinuta = int.parse(doParts[1]);

              final od = DateTime(
                dataZajec.year,
                dataZajec.month,
                dataZajec.day,
                odGodzina,
                odMinuta,
              );

              final do_ = DateTime(
                dataZajec.year,
                dataZajec.month,
                dataZajec.day,
                doGodzina,
                doMinuta,
              );

              // Generuj UID
              final contentToHash = '${nauczyciel.id}-$przedmiot-$od-$do_-$miejsce';
              final uid = _generateUid(contentToHash);

              final plan = PlanNauczyciela(
                uid: uid,
                nauczycielId: nauczyciel.id!,
                od: od,
                do_: do_,
                przedmiot: przedmiot,
                rz: rzText,
                miejsce: miejsce,
                terminy: terminy,
              );

              planyList.add(plan);

              // Zapisujemy linki do grup znalezionych w planie
              final grupaLinks = cells[4].querySelectorAll('a[href*="grupy_plan.php?ID="]');
              for (final grupaLink in grupaLinks) {
                final grupaUrl = grupaLink.attributes['href'];
                final grupaNazwa = grupaLink.text.trim();
                final grupaIdMatch = RegExp(r'ID=(\d+)').firstMatch(grupaUrl ?? '');

                if (grupaIdMatch != null) {
                  final grupaUrlId = grupaIdMatch.group(1)!;
                  Logger.info('Znaleziono grupę: $grupaNazwa, ID: $grupaUrlId dla nauczyciela ${nauczyciel.nazwa}');
                }
              }
            }
          } catch (e) {
            Logger.error('Błąd podczas parsowania wiersza planu: $e');
          }
        }
      }

      // Zapisz plany do bazy danych
      if (planyList.isNotEmpty) {
        Logger.info('Znaleziono ${planyList.length} zajęć dla nauczyciela ${nauczyciel.nazwa}');
        await supabaseService.batchInsertPlanyNauczycieli(planyList);
      } else {
        Logger.info('Nie znaleziono zajęć dla nauczyciela ${nauczyciel.nazwa}');
      }
    } else {
      Logger.error('Błąd pobierania planu nauczyciela: ${response.statusCode}');
    }
  } catch (e) {
    Logger.error('Błąd podczas scrapowania planu nauczyciela ${nauczyciel.nazwa}: $e');
  }
}