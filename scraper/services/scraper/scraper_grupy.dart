import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

Future<List<Grupa>> scrapeGrupy(Kierunek kierunek, SupabaseService supabaseService) async {
  try {
    Logger.info('Pobieranie grup dla kierunku: ${kierunek.nazwa}');

    final url = 'https://aplikacje.uz.zgora.pl/studia/plan.php?kierunek=${kierunek.url}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Nie udało się pobrać grup dla kierunku: ${response.statusCode}');
    }

    final document = parse(response.body);
    final grupyElements = document.querySelectorAll('select[name="grupa"] option');

    final grupy = <Grupa>[];
    for (var element in grupyElements) {
      final valueAttr = element.attributes['value'];
      if (valueAttr == null || valueAttr.isEmpty) continue;

      final grupa = Grupa(
        id: null,
        nazwa: element.text,
        urlIcs: valueAttr, // Poprawiona nazwa parametru z 'url' na 'urlIcs'
        kierunekId: kierunek.id!,
      );

      final savedGrupa = await supabaseService.createOrUpdateGrupa(grupa);
      grupy.add(savedGrupa);
    }

    return grupy;
  } catch (e, stack) {
    Logger.error('Błąd podczas pobierania grup dla kierunku ${kierunek.nazwa}: $e');
    Logger.error('Stack: $stack');
    return [];
  }
}