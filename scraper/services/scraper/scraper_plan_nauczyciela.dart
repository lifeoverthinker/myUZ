import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

Future<void> scrapePlanNauczyciela(
    List<Nauczyciel> nauczyciele, SupabaseService supabaseService) async {
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
        // Przetwarzanie pliku ICS
        final icalendar = ICalendar.fromString(response.body);
        final events =
            icalendar.data.where((data) => data['type'] == 'VEVENT').toList();

        final plany = events.map((event) {
          return PlanNauczyciela(
            uid: event['uid'],
            nauczycielId: nauczyciel.id,
            od: DateTime.parse(event['dtstart']),
            do_: DateTime.parse(event['dtend']),
            przedmiot: event['summary'],
            rz: event['description'],
            miejsce: event['location'],
            terminy: event['rrule'],
            ostatniaAktualizacja: DateTime.now(),
          );
        }).toList();

        await supabaseService.batchInsertPlanNauczyciela(plany);
      } else {
        Logger.warning(
            'Nie udalo sie pobrac planu dla nauczyciela: ${nauczyciel.nazwa}');
      }
    }

    Logger.info('Zakonczono aktualizacje planow nauczycieli');
  } catch (e, stack) {
    Logger.error('Blad podczas pobierania planow nauczycieli: $e');
    Logger.error('Stack trace: $stack');
  }
}
