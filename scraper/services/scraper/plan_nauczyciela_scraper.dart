import 'package:html/parser.dart' as parser;
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'scraper_base.dart';

class PlanNauczycielaScraper extends ScraperBase {
  PlanNauczycielaScraper();

  Future<List<PlanNauczyciela>> scrapePlanNauczyciela(
      Nauczyciel nauczyciel) async {
    Logger.info(
        'Pobieranie planu nauczyciela: ${nauczyciel.nazwa ?? nauczyciel.id}');

    final html = await fetchPage(nauczyciel.urlPlan);
    final document = parser.parse(html);
    final planyList = <PlanNauczyciela>[];

    final events = document.querySelectorAll('.event');

    for (final event in events) {
      final dataGodzinyElement = event.querySelector('.date');
      final przedmiotElement = event.querySelector('.title');
      final miejsceElement = event.querySelector('.location');

      if (dataGodzinyElement != null && przedmiotElement != null) {
        final dataGodziny = dataGodzinyElement.text;
        final przedmiot = przedmiotElement.text;
        final miejsce = miejsceElement?.text;

        // Przykładowy format: "2023-10-15 10:00-11:45"
        final parts = dataGodziny.split(' ');
        if (parts.length >= 2) {
          final data = parts[0];
          final godziny = parts[1].split('-');

          if (godziny.length >= 2) {
            try {
              final dataOd = DateTime.parse('${data}T${godziny[0]}:00');
              final dataDo = DateTime.parse('${data}T${godziny[1]}:00');

              // Pobierz rodzaj zajęć (W, Ć, L...)
              final rzMatch =
                  RegExp(r'\b([WĆLPSćwlps])\b').firstMatch(przedmiot);
              final rz = rzMatch?.group(1);

              // Generuj UID
              final contentToHash =
                  '${nauczyciel.id}-$przedmiot-$dataOd-$dataDo-$miejsce';
              final bytes = utf8.encode(contentToHash);
              final digest = sha256.convert(bytes);
              final uid = digest.toString();

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
            } catch (e) {
              Logger.error('Błąd parsowania daty: $e');
            }
          }
        }
      }
    }

    Logger.info('Pobrano ${planyList.length} planów nauczyciela');
    return planyList;
  }
}
