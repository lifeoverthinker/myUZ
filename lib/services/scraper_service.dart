import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:my_uz/services/supabase_service.dart';
import 'package:my_uz/services/ics_parser.dart';

class ScraperService {
  final SupabaseService _supabase = SupabaseService();
  final Logger _logger = Logger();

  Future<void> scrapujPlany() async {
    try {
      _logger.i('Pobieranie nauczycieli...');
      final nauczyciele = await _supabase.pobierzNauczycieli();
      _logger.i('Pobrano ${nauczyciele.length} nauczycieli z planami');

      for (var nauczyciel in nauczyciele) {
        if (nauczyciel.urlPlan?.isEmpty ?? true) continue;

        try {
          _logger.i('Pobieram plan dla: ${nauczyciel.nazwa}');
          final response = await http.get(Uri.parse(nauczyciel.urlPlan!));

          if (response.statusCode == 200) {
            final zajecia = IcsParser.parsujZajecia(response.body);
            _logger.i('Zapisuję ${zajecia.length} zajęć dla ${nauczyciel.nazwa}');
            await _supabase.zapiszZajecia(zajecia);
          } else {
            _logger.w('Nie udało się pobrać planu dla ${nauczyciel.nazwa}. Status: ${response.statusCode}');
          }
        } catch (e) {
          _logger.e('Błąd przy przetwarzaniu nauczyciela ${nauczyciel.nazwa}', error: e);
        }
      }
    } catch (e) {
      _logger.e('Błąd scrapowania planów nauczycieli', error: e);
      rethrow; // Używamy rethrow zamiast throw e
    }
  }
}