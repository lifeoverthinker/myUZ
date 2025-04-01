import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:my_uz/services/supabase_service.dart';
import 'package:my_uz/services/ics_parser.dart';

class ScraperService {
  final SupabaseService _supabase = SupabaseService();
  final Logger _logger = Logger();

  Future<void> scrapujPlany() async {
    try {
      final grupy = await _supabase.pobierzGrupy();

      await Future.wait(grupy.map((grupa) async {
        final icsUrl = grupa.urlIcs;
        final response = await http.get(Uri.parse(icsUrl));

        if (response.statusCode == 200) {
          final zajecia = IcsParser.parsujZajecia(
            response.body,
            grupaId: grupa.id,
          );
          await _supabase.zapiszZajecia(zajecia);
          _logger.i('Zapisano zajęcia dla grupy ${grupa.nazwa}');
        } else {
          _logger.e('Błąd pobierania ICS dla ${grupa.nazwa} (${response.statusCode})');
        }
      }));

    } catch (e) {
      _logger.e('❗ Krytyczny błąd scrapowania', error: e);
    }
  }
}