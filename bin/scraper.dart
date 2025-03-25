import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/utils/logger.dart';

const baseUrl = 'https://e-uczelnia.uz.zgora.pl';

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
      var document = parser.parse(response.body);
      var links = document.querySelectorAll('a.list-group-item');

      for (var link in links) {
        final url = link.attributes['href'];
        final nazwa = link.text.trim();

        if (url != null && url.contains('grupa=')) {
          final urlIcs = '$baseUrl/timetable2/$url&format=ical';
          final grupa = Grupa(
            nazwa: nazwa,
            kierunekId: kierunek.id,
            urlIcs: urlIcs,
          );

          await supabaseService.createOrUpdateGrupa(grupa);
        }
      }
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

// Dodana brakująca funkcja
Future<void> scrapePlanyNauczycieli(List<Nauczyciel> nauczyciele, SupabaseService supabaseService) async {
  Logger.info('Rozpoczęto aktualizację planów nauczycieli');
  int count = 0;

  for (final nauczyciel in nauczyciele) {
    await scrapePlanNauczyciela(nauczyciel, supabaseService);
    count++;

    if (count % 10 == 0) {
      Logger.info('Zaktualizowano plany $count/${nauczyciele.length} nauczycieli');
    }
  }

  Logger.info('Zakończono aktualizację planów nauczycieli');
}

Future<void> scrapePlanNauczyciela(Nauczyciel nauczyciel, SupabaseService supabaseService) async {
  try {
    final response = await http.get(Uri.parse(nauczyciel.urlPlan));
    if (response.statusCode == 200) {
      // Najpierw usuń stare zajęcia
      await supabaseService.deleteZajeciaForNauczyciel(nauczyciel.id!);

      // Przetwarzanie HTML planu nauczyciela
      final htmlContent = response.body;
      final List<PlanNauczyciela> planyList = [];

      // Podobny schemat parsowania jak dla zajęć grup
      final regex = RegExp(r'<div class="event">(.*?)</div>', dotAll: true);
      final matches = regex.allMatches(htmlContent);

      for (final match in matches) {
        final eventContent = match.group(1)!;

        // Parsowanie daty i godzin
        final dataGodzinyMatch =
            RegExp(r'<div class="date">(.*?)</div>', dotAll: true)
                .firstMatch(eventContent);
        final przedmiotMatch =
            RegExp(r'<div class="title">(.*?)</div>', dotAll: true)
                .firstMatch(eventContent);
        final miejsceMatch =
            RegExp(r'<div class="location">(.*?)</div>', dotAll: true)
                .firstMatch(eventContent);

        if (dataGodzinyMatch != null && przedmiotMatch != null) {
          // Przetwarzanie daty i godziny
          final dataGodziny = dataGodzinyMatch.group(1)!;
          // Przykładowy format: "2023-10-15 10:00-11:45"
          final parts = dataGodziny.split(' ');
          final data = parts[0];
          final godziny = parts[1].split('-');

          final dataOd = DateTime.parse('${data}T${godziny[0]}:00');
          final dataDo = DateTime.parse('${data}T${godziny[1]}:00');

          final przedmiot = przedmiotMatch.group(1)!;
          final miejsce = miejsceMatch?.group(1);

          // Pobierz rodzaj zajęć (W, Ć, L...)
          final rzMatch = RegExp(r'\b([WĆLPSćwlps])\b').firstMatch(przedmiot);
          final rz = rzMatch?.group(1);

          // Generuj UID
          final contentToHash =
              '${nauczyciel.id}-$przedmiot-$dataOd-$dataDo-$miejsce';
          final uid = _generateUid(contentToHash);

          final plan = PlanNauczyciela(
            uid: uid,
            nauczycielId: nauczyciel.id,
            od: dataOd,
            do_: dataDo,
            przedmiot: przedmiot,
            rz: rz,
            miejsce: miejsce,
          );

          planyList.add(plan);
        }
      }

      // Zapisz plany do bazy danych
      if (planyList.isNotEmpty) {
        await supabaseService.batchInsertPlanyNauczycieli(planyList);
      }
    }
  } catch (e) {
    Logger.error(
        'Błąd podczas pobierania planu nauczyciela ${nauczyciel.nazwa ?? nauczyciel.id}: $e');
  }
}