import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';

Future<List<Kierunek>> scrapeKierunki(SupabaseService supabaseService) async {
  try {
    Logger.info('Rozpoczynam pobieranie kierunków...');

    final response = await http.get(Uri.parse('https://aplikacje.uz.zgora.pl/studia/'));
    if (response.statusCode != 200) {
      throw Exception('Nie udało się pobrać strony kierunków: ${response.statusCode}');
    }

    final document = parse(response.body);
    final kierunkiElements = document.querySelectorAll('select[name="kierunek"] option');

    final kierunki = <Kierunek>[];
    for (var element in kierunkiElements) {
      final valueAttr = element.attributes['value'];
      if (valueAttr == null || valueAttr.isEmpty) continue;

      final kierunek = Kierunek(
        id: null,
        nazwa: element.text,
        url: valueAttr,
      );

      final savedKierunek = await supabaseService.createOrUpdateKierunek(kierunek);
      kierunki.add(savedKierunek);
    }

    return kierunki;
  } catch (e, stack) {
    Logger.error('Błąd podczas pobierania kierunków: $e');
    Logger.error('Stack: $stack');
    return [];
  }
}