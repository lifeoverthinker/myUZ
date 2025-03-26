import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

Future<void> scrapeNauczyciel(List<Nauczyciel> nauczyciele, SupabaseService supabaseService, {Map<String, dynamic>? checkpoint}) async {
  try {
    Logger.info('Rozpoczynam pobieranie zajęć dla ${nauczyciele.length} nauczycieli');
    final uuid = Uuid();

    for (var nauczyciel in nauczyciele) {
      Logger.info('Przetwarzanie zajęć dla: ${nauczyciel.nazwa}');

      final url = 'https://aplikacje.uz.zgora.pl/studia/plan_nauczyciela.php?id=${nauczyciel.urlId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        Logger.error('Nie udało się pobrać zajęć dla nauczyciela: ${response.statusCode}');
        continue;
      }

      final document = parse(response.body);
      final zajeciaElements = document.querySelectorAll('table.plan tr:not(:first-child)');

      for (var element in zajeciaElements) {
        final cells = element.querySelectorAll('td');
        if (cells.length < 5) continue;

        final przedmiot = cells[0].text.trim();
        final grupaText = cells[1].text.trim();
        final dataStr = cells[2].text.trim();
        final godzinaRozpoczecia = cells[3].text.trim();
        final godzinaZakonczenia = cells[4].text.trim();
        final miejsce = cells.length > 5 ? cells[5].text.trim() : null;
        final rz = cells.length > 6 ? cells[6].text.trim() : null;

        try {
          final formatter = DateFormat('dd.MM.yyyy HH:mm');
          final od = formatter.parse('$dataStr $godzinaRozpoczecia');
          final do_ = formatter.parse('$dataStr $godzinaZakonczenia');

          final planNauczyciela = PlanNauczyciela(
            uid: uuid.v4(),
            od: od,
            do_: do_,
            przedmiot: przedmiot,
            nauczycielId: nauczyciel.id,
            miejsce: miejsce,
            rz: rz,
            terminy: grupaText // Zapisujemy informację o grupie w polu terminy
          );

          await supabaseService.savePlanNauczyciela(planNauczyciela);
        } catch (e) {
          Logger.error('Błąd parsowania daty dla zajęć nauczyciela: $e');
          continue;
        }
      }
    }
  } catch (e, stack) {
    Logger.error('Błąd podczas scrapowania zajęć nauczycieli: $e');
    Logger.error('Stack: $stack');
  }
}