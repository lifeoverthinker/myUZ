import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/plan_nauczyciela.dart';
import 'package:my_uz/utils/logger.dart';

class SupabaseService {
  final String url;
  final String serviceRoleKey;
  late final SupabaseClient _client;

  SupabaseService({required this.url, required this.serviceRoleKey}) {
    _client = SupabaseClient(url, serviceRoleKey);
    Logger.info('Inicjalizacja serwisu Supabase: $url');
  }

  // ===== KIERUNKI =====

  Future<int> createOrUpdateKierunek(Kierunek kierunek) async {
    try {
      final response = await _client
          .from('kierunki')
          .upsert(kierunek.toJson())
          .select('id')
          .single();

      return response['id'];
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas zapisywania kierunku', e, stackTrace);
      rethrow;
    }
  }

  // ===== GRUPY =====

  Future<int> createOrUpdateGrupa(Grupa grupa) async {
    try {
      final response = await _client
          .from('grupy')
          .upsert(grupa.toJson())
          .select('id')
          .single();

      return response['id'];
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas zapisywania grupy', e, stackTrace);
      rethrow;
    }
  }

  // ===== ZAJĘCIA =====

  Future<void> saveZajecia(List<Zajecia> zajecia) async {
    if (zajecia.isEmpty) return;

    try {
      await _client.from('zajecia').upsert(
            zajecia.map((z) => z.toJson()).toList(),
          );
      Logger.info('Zapisano ${zajecia.length} zajęć');
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas zapisywania zajęć', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteZajeciaForNauczyciel(int nauczycielId) async {
    try {
      await _client.from('zajecia').delete().eq('nauczyciel_id', nauczycielId);
      Logger.info('Usunięto zajęcia dla nauczyciela: $nauczycielId');
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas usuwania zajęć nauczyciela', e, stackTrace);
      rethrow;
    }
  }

  // ===== PLANY NAUCZYCIELI =====

  Future<void> batchInsertPlanNauczyciela(List<PlanNauczyciela> plany) async {
    if (plany.isEmpty) return;

    try {
      await _client.from('plany_nauczycieli').upsert(
            plany.map((p) => p.toJson()).toList(),
          );
      Logger.info('Zapisano ${plany.length} planów nauczycieli');
    } catch (e, stackTrace) {
      Logger.error(
          'Błąd podczas zapisywania planów nauczycieli', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteZajeciaForNauczycielFromPlany(int nauczycielId) async {
    try {
      await _client
          .from('plany_nauczycieli')
          .delete()
          .eq('nauczyciel_id', nauczycielId);
      Logger.info('Usunięto plany dla nauczyciela: $nauczycielId');
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas usuwania planów nauczyciela', e, stackTrace);
      rethrow;
    }
  }

  // ===== NAUCZYCIELE =====

  Future<List<int>> getUniqueNauczycielIds() async {
    try {
      final response = await _client
          .from('zajecia')
          .select('nauczyciel_id')
          .not('nauczyciel_id', 'is', null);

      final idSet = <int>{};

      for (final item in response) {
        final id = item['nauczyciel_id'];
        if (id != null) {
          idSet.add(id);
        }
      }

      return idSet.toList();
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas pobierania ID nauczycieli', e, stackTrace);
      return [];
    }
  }

  Future<int> saveNauczyciel(Nauczyciel nauczyciel) async {
    try {
      await _client.from('nauczyciele').upsert(nauczyciel.toJson());
      return nauczyciel.id;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas zapisywania nauczyciela', e, stackTrace);
      rethrow;
    }
  }

  Future<Nauczyciel?> getNauczycielById(int id) async {
    try {
      final response =
          await _client.from('nauczyciele').select().eq('id', id).single();

      return Nauczyciel.fromJson(response);
    } catch (e) {
      Logger.warning('Nauczyciel o ID $id nie istnieje');
      return null;
    }
  }
}