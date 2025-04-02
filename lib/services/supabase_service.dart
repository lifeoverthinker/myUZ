import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_uz/models/nauczyciel_model.dart';
import 'package:my_uz/models/kierunek_model.dart';
import 'package:my_uz/models/grupa_model.dart';
import 'package:my_uz/models/zajecia_model.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  // Metody do nauczycieli
  Future<List<Nauczyciel>> pobierzNauczycieli() async {
    _logger.i('Pobieranie nauczycieli z bazy...');
    final response = await _supabase.from('nauczyciele').select();

    _logger.d('Pobrano dane: ${response.length} nauczycieli');
    return (response as List).map((json) => Nauczyciel.fromJson(json)).toList();
  }

  Future<Nauczyciel> dodajNauczyciela(Nauczyciel nauczyciel) async {
    _logger.i('Dodawanie nauczyciela: ${nauczyciel.nazwa}');
    final response = await _supabase
        .from('nauczyciele')
        .insert(nauczyciel.toJson())
        .select()
        .single();

    _logger.d('Dodano nauczyciela z ID: ${response['id']}');
    return Nauczyciel.fromJson(response);
  }

  // Metoda do zajęć
  Future<void> zapiszZajecia(List<Zajecia> zajecia) async {
    if (zajecia.isEmpty) {
      _logger.w('Próba zapisu pustej listy zajęć');
      return;
    }

    _logger.i('Zapisywanie ${zajecia.length} zajęć do bazy...');

    // Poprawka: usunięto niepotrzebny operator ?.
    final dataToInsert = zajecia.map((z) => z.toJson()).toList();

    await _supabase.from('zajecia').upsert(dataToInsert, onConflict: 'uid');

    _logger.i('Zapisano zajęcia do bazy');
  }

  // Metoda do sprawdzania liczby zajęć (dla testów)
  Future<int> liczbaZajecWBazie() async {
    _logger.i('Sprawdzanie liczby zajęć w bazie...');
    final response = await _supabase.from('zajecia').select('uid');

    _logger.d('Liczba zajęć w bazie: ${response.length}');
    return response.length;
  }

  // Kierunki
  Future<List<Kierunek>> pobierzKierunki() async {
    _logger.i('Pobieranie kierunków z bazy...');
    final response = await _supabase.from('kierunki').select();

    _logger.d('Pobrano ${response.length} kierunków');
    return (response as List).map((json) => Kierunek.fromJson(json)).toList();
  }

  // Grupy
  Future<List<Grupa>> pobierzGrupy({int? kierunekId}) async {
    // Poprawka: użyto interpolacji zamiast operatora +
    _logger.i(
        'Pobieranie grup${kierunekId != null ? " dla kierunku $kierunekId" : ""}');
    var query = _supabase.from('grupy').select();

    if (kierunekId != null) {
      query = query.eq('kierunek_id', kierunekId);
    }

    final response = await query;

    _logger.d('Pobrano ${response.length} grup');
    return (response as List).map((json) => Grupa.fromJson(json)).toList();
  }
}
