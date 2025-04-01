import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_uz/models/zajecia_model.dart';
import 'package:my_uz/models/grupa_model.dart';

class SupabaseService {
  late final SupabaseClient _client;

  SupabaseService() {
    _client = Supabase.instance.client;
  }

  // 🔴 Dodaj metody CRUD dla Twoich tabel:

  // Pobierz wszystkie grupy
  Future<List<Grupa>> pobierzGrupy() async {
    final response = await _client.from('grupy').select();
    return response.map((json) => Grupa.fromJson(json)).toList();
  }

  // Zapisz zajęcia do bazy (upsert - aktualizuj jeśli istnieje)
  Future<void> zapiszZajecia(List<Zajecia> zajecia) async {
    await _client.from('zajecia').upsert(
      zajecia.map((z) => z.toJson()).toList(),
    );
  }

// 🔴 Dodaj inne metody według potrzeb (np. dla nauczycieli)
}