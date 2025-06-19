import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/debug_helper.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  // Podpowiedzi kodów grup (max 10)
  Future<List<Map<String, dynamic>>> fetchGroupSuggestions(String query) async {
    final response = await Supabase.instance.client
        .from('grupy')
        .select('kod_grupy')
        .ilike('kod_grupy', '%$query%');
    return List<Map<String, dynamic>>.from(response);
  }

  // Podpowiedzi podgrup dla danej grupy
  Future<List<String>> fetchPodgrupyForGroup(String kodGrupy) async {
    try {
      final groupResponse = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', kodGrupy)
          .single();
      final groupId = groupResponse['id'] as String;
      final response = await client
          .from('zajecia_grupy')
          .select('podgrupa')
          .eq('grupa_id', groupId)
          .order('podgrupa');
      final podgrupy =
      response.map((r) => r['podgrupa'] as String).toSet().toList();
      return podgrupy;
    } catch (e) {
      print('Error fetching subgroups: $e');
      return [];
    }
  }

  // Pobierz kierunek i wydział dla grupy
  Future<Map<String, String>> fetchKierunekWydzialForGroupByKod(
      String kodGrupy,
      ) async {
    try {
      final response = await client
          .from('grupy')
          .select('kierunki(nazwa, wydzial), tryb_studiow')
          .eq('kod_grupy', kodGrupy)
          .single();
      final kierunki = response['kierunki'] as Map;
      return {
        'kierunek': kierunki['nazwa'] as String,
        'wydzial': kierunki['wydzial'] as String,
        'tryb_studiow': response['tryb_studiow'] as String,
      };
    } catch (e) {
      return {};
    }
  }

  // Zwraca listę przedmiotów dla grupy (dla Index screen)
  Future<List<String>> fetchSubjectsForGroup(String kodGrupy) async {
    try {
      final groupResponse = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', kodGrupy)
          .single();
      final groupId = groupResponse['id'] as String;
      final response = await client
          .from('zajecia_grupy')
          .select('przedmiot')
          .eq('grupa_id', groupId)
          .order('przedmiot');
      final subjects =
      response.map((r) => r['przedmiot'] as String).toSet().toList();
      return List<String>.from(subjects);
    } catch (e) {
      return [];
    }
  }

  // Zwraca unikalne typy sekcji dla grupy (dla Index screen)
  Future<List<String>> fetchUniqueSectionTypesForGroup(String kodGrupy) async {
    try {
      final groupResponse = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', kodGrupy)
          .single();
      final groupId = groupResponse['id'] as String;
      final response = await client
          .from('zajecia_grupy')
          .select('rz')
          .eq('grupa_id', groupId)
          .order('rz');
      final types = response.map((r) => r['rz'] as String).toSet().toList();
      return List<String>.from(types);
    } catch (e) {
      return [];
    }
  }

  // Zwraca najbliższe zajęcia dla grupy (dla Home screen)
  Future<List<Map<String, dynamic>>> fetchNajblizszeZajecia(
      String kodGrupy,
      ) async {
    try {
      final groupResponse = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', kodGrupy)
          .single();
      final groupId = groupResponse['id'] as String;
      final now = DateTime.now();
      final response = await client
          .from('zajecia_grupy')
          .select('*')
          .eq('grupa_id', groupId)
          .gte('od', now.toIso8601String())
          .order('od')
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Zajęcia dla danego dnia, grupy i podgrupy (dla Calendar screen)
  Future<List<Map<String, dynamic>>> fetchZajeciaForDay(
      DateTime day,
      String kodGrupy,
      String podgrupa,
      ) async {
    try {
      // Pobierz ID grupy
      final groupResponse = await client
          .from('grupy')
          .select('id')
          .eq('kod_grupy', kodGrupy)
          .maybeSingle();
      if (groupResponse == null) return [];
      final groupId = groupResponse['id'] as String;
      // Przygotuj zakres czasowy
      final start =
      DateTime(day.year, day.month, day.day, 0, 0, 0).toIso8601String();
      final end =
      DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
      List response;
      if (podgrupa.isNotEmpty) {
        // Filtruj po konkretnej podgrupie ORAZ zajęcia bez podgrupy (ogólne)
        final responsePodgrupa = await client
            .from('zajecia_grupy')
            .select('*')
            .eq('grupa_id', groupId)
            .eq('podgrupa', podgrupa)
            .gte('od', start)
            .lte('od', end)
            .order('od');
        final responseOgolne = await client
            .from('zajecia_grupy')
            .select('*')
            .eq('grupa_id', groupId)
            .or('podgrupa.is.null,podgrupa.eq.')
            .gte('od', start)
            .lte('od', end)
            .order('od');
        response = [...responsePodgrupa, ...responseOgolne];
      } else {
        response = await client
            .from('zajecia_grupy')
            .select('*')
            .eq('grupa_id', groupId)
            .gte('od', start)
            .lte('od', end)
            .order('od');
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      DebugHelper.logError('fetchZajeciaForDay failed', error: e);
      return [];
    }
  }

  // Podsumowanie profilu dla danej grupy/podgrupy
  Future<Map<String, String>> fetchProfileSummary(
      String kodGrupy,
      String podgrupa,
      ) async {
    try {
      final response = await client
          .from('grupy')
          .select('kierunki(nazwa, wydzial), tryb_studiow')
          .eq('kod_grupy', kodGrupy)
          .single();
      final kierunki = response['kierunki'] as Map?;
      return {
        'kierunek': kierunki?['nazwa'] ?? '-',
        'wydzial': kierunki?['wydzial'] ?? '-',
        'group': kodGrupy,
        'podgrupa': podgrupa,
        'tryb': response['tryb_studiow'] ?? '-',
      };
    } catch (e) {
      return {};
    }
  }

  // Dodaj grupę do profilu użytkownika
  Future addGroup(
      String userId,
      String kodGrupy,
      String? podgrupa,
      ) async {
    try {
      final groupInfo = await fetchKierunekWydzialForGroupByKod(kodGrupy);
      if (groupInfo.isNotEmpty) {
        final response = await client
            .from('profiles')
            .select('groups')
            .eq('id', userId)
            .maybeSingle();
        List groups = response?['groups'] ?? [];
        groups.add({
          'kod_grupy': kodGrupy,
          'podgrupa': podgrupa,
          'kierunek': groupInfo['kierunek'],
          'wydzial': groupInfo['wydzial'],
          'tryb_studiow': groupInfo['tryb_studiow'],
        });
        await client.from('profiles').upsert({'id': userId, 'groups': groups});
      }
    } catch (e) {}
  }

  // Usuń grupę z profilu użytkownika
  Future deleteGroup(
      String userId,
      String kodGrupy,
      String? podgrupa,
      ) async {
    try {
      final response = await client
          .from('profiles')
          .select('groups')
          .eq('id', userId)
          .single();
      final groups = List.from(response['groups']);
      groups.removeWhere(
            (group) =>
        group['kod_grupy'] == kodGrupy && group['podgrupa'] == podgrupa,
      );
      await client.from('profiles').upsert({'id': userId, 'groups': groups});
    } catch (e) {}
  }

  // Zaktualizuj imię i nazwisko użytkownika
  Future updateUserName(String userId, String fullName) async {
    try {
      final parts = fullName.trim().split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      await client.from('profiles').upsert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
      });
    } catch (e) {}
  }
}
