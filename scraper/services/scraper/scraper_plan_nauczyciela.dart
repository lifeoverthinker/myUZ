import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

Future<void> scrapePlanNauczyciela(List<Nauczyciel> nauczyciele, SupabaseService supabaseService) async {
  try {
    Logger.info('Rozpoczeto aktualizacje planow nauczycieli');

    for (var nauczyciel in nauczyciele) {
      if (nauczyciel.nazwa?.isEmpty ?? true) {
        Logger.warning('Pomijanie nauczyciela z pusta nazwa');
        continue;
      }

      Logger.info('Pobieranie planu dla nauczyciela: ${nauczyciel.nazwa}');

      // Pobieramy plik ICS
      final response = await http.get(Uri.parse(nauczyciel.urlPlan));

      if (response.statusCode == 200) {
        final icsString = response.body;
        final icsData = ICalendar.fromString(icsString);

        List<PlanNauczyciela> plany = [];

        for (var event in icsData.data) {
          final uid = event['UID'] as String?;
          final dtstart = event['DTSTART'] as DateTime?;
          final dtend = event['DTEND'] as DateTime?;
          final summary = event['SUMMARY'] as String?;
          final location = event['LOCATION'] as String?;
          final description = event['DESCRIPTION'] as String?;

          if (uid != null && dtstart != null && dtend != null && summary != null) {
            final plan = PlanNauczyciela(
              uid: uid,
              nauczycielId: nauczyciel.id!,
              od: dtstart,
              do_: dtend,
              przedmiot: summary,
              rz: description ?? '',
              miejsce: location ?? '',
              terminy: '',
            );

            plany.add(plan);
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