import 'package:supabase/supabase.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/config/app_config.dart';
import 'package:my_uz/utils/logger.dart';

class SupabaseService {
  late final SupabaseClient _client;

  SupabaseService() {
    _client = SupabaseClient(
      AppConfig.supabaseUrl, // Dostosuj nazwę klasy/zmiennej
      AppConfig.supabaseKey, // Dostosuj nazwę klasy/zmiennej
    );
  }

  // Metody dla nauczycieli
  Future<Nauczyciel?> getNauczycielByUrlId(String? urlId) async {
    if (urlId == null) return null;

    final response = await _client
        .from('nauczyciele')
        .select()
        .eq('url_id', urlId)
        .maybeSingle();

    if (response == null) return null;
    return Nauczyciel.fromJson(response);
  }

  Future<Nauczyciel?> getNauczycielByUrlPlan(String urlPlan) async {
    final response = await _client
        .from('nauczyciele')
        .select()
        .eq('url_plan', urlPlan)
        .maybeSingle();

    if (response == null) return null;
    return Nauczyciel.fromJson(response);
  }

  Future<Nauczyciel> createOrUpdateNauczyciel(Nauczyciel nauczyciel) async {
    // Sprawdź, czy nauczyciel już istnieje
    final existingNauczyciel = await getNauczycielByUrlId(nauczyciel.urlId);

    if (existingNauczyciel != null) {
      // Użyj .toString() dla int?
      await _client
          .from('nauczyciele')
          .update(nauczyciel.toJson())
          .eq('id', existingNauczyciel.id.toString());
      return nauczyciel.copyWith(id: existingNauczyciel.id);
    } else {
      final response = await _client
          .from('nauczyciele')
          .insert(nauczyciel.toJson())
          .select()
          .single();
      return Nauczyciel.fromJson(response);
    }
  }

  Future<List<Nauczyciel>> getAllNauczyciele() async {
    try {
      final response = await _client.from('nauczyciele').select();
      return response.map<Nauczyciel>((json) => Nauczyciel.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Błąd podczas pobierania nauczycieli: $e');
      return [];
    }
  }

  // Metody dla planów nauczycieli
  Future<void> deleteZajeciaForNauczyciel(int nauczycielId) async {
    try {
      await _client
          .from('plany_nauczycieli')
          .delete()
          .eq('nauczyciel_id', nauczycielId);
      Logger.info('Usunięto stare zajęcia nauczyciela: $nauczycielId');
    } catch (e) {
      Logger.error('Błąd podczas usuwania zajęć nauczyciela: $e');
    }
  }

  Future<void> batchInsertPlanNauczyciela(List<PlanNauczyciela> plany) async {
    final data = plany.map((plan) => plan.toJson()).toList();
    await _client.from('plany_nauczycieli').upsert(data);
    Logger.info('Dodano ${plany.length} planów nauczyciela');
  }

  // Metody dla kierunków
  Future<Kierunek?> getKierunekByUrl(String url) async {
    final response =
        await _client.from('kierunki').select().eq('url', url).maybeSingle();

    if (response == null) return null;
    return Kierunek.fromJson(response);
  }

  Future<Kierunek> createOrUpdateKierunek(Kierunek kierunek) async {
    // Sprawdź, czy kierunek już istnieje
    final existingKierunek = await getKierunekByUrl(kierunek.url);

    if (existingKierunek != null) {
      // Użyj .toString() dla int?
      await _client
          .from('kierunki')
          .update(kierunek.toJson())
          .eq('id', existingKierunek.id.toString());
      return kierunek.copyWith(id: existingKierunek.id);
    } else {
      final response = await _client
          .from('kierunki')
          .insert(kierunek.toJson())
          .select()
          .single();
      return Kierunek.fromJson(response);
    }
  }

  Future<List<Kierunek>> getAllKierunki() async {
    final response = await _client.from('kierunki').select().order('nazwa');

    return response.map<Kierunek>((json) => Kierunek.fromJson(json)).toList();
  }

  // Metody dla grup
  Future<Grupa?> getGrupaByUrlIcs(String urlIcs) async {
    final response = await _client
        .from('grupy')
        .select()
        .eq('url_ics', urlIcs)
        .maybeSingle();

    if (response == null) return null;
    return Grupa.fromJson(response);
  }

  Future<Grupa> createOrUpdateGrupa(Grupa grupa) async {
    // Sprawdź, czy grupa już istnieje
    final existingGrupa = await getGrupaByUrlIcs(grupa.urlIcs);

    if (existingGrupa != null) {
      // Użyj .toString() dla int?
      await _client
          .from('grupy')
          .update(grupa.toJson())
          .eq('id', existingGrupa.id.toString());
      return grupa.copyWith(id: existingGrupa.id);
    } else {
      final response =
          await _client.from('grupy').insert(grupa.toJson()).select().single();
      return Grupa.fromJson(response);
    }
  }

  Future<List<Grupa>> getGrupyByKierunekId(int kierunekId) async {
    final response = await _client
        .from('grupy')
        .select()
        .eq('kierunek_id', kierunekId)
        .order('nazwa');

    return response.map<Grupa>((json) => Grupa.fromJson(json)).toList();
  }

  // Metody dla zajęć
  Future<void> deleteZajeciaForGrupa(int grupaId) async {
    await _client.from('zajecia').delete().eq('grupa_id', grupaId);
    Logger.info('Usunięto stare zajęcia grupy: $grupaId');
  }

  Future<void> batchInsertZajecia(List<Zajecia> zajecia) async {
    const batchSize = 100; // Optymalna wielkość partii
    for (var i = 0; i < zajecia.length; i += batchSize) {
      final end =
          (i + batchSize < zajecia.length) ? i + batchSize : zajecia.length;
      final batch = zajecia.sublist(i, end);
      final data = batch.map((z) => z.toJson()).toList();
      await _client.from('zajecia').upsert(data);
      Logger.info(
          'Dodano partię ${batch.length} zajęć (${i + batch.length}/${zajecia.length})');
    }
  }

  Future<void> batchInsertPlanyNauczycieli(List<PlanNauczyciela> plany) async {
    try {
      final data = plany.map((plan) => plan.toJson()).toList();
      await _client.from('plany_nauczycieli').upsert(data);
    } catch (e) {
      Logger.error('Błąd podczas dodawania planów nauczycieli: $e');
    }
  }
}
