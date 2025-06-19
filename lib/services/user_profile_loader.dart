import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/profile/user_profile.dart';
import '../components/profile/group_profile.dart';

Future<void> loadUserProfileFromDb() async {
  print('DEBUG: loadUserProfileFromDb() rozpoczęte');

  final userId = Supabase.instance.client.auth.currentUser?.id;
  print('DEBUG: userId = $userId');

  if (userId == null) {
    return;
  }


  try {
    // Pobierz profil użytkownika z bazą grup
    final profileData = await Supabase.instance.client
        .from('profiles')
        .select('first_name, last_name, avatar_url, groups')
        .eq('id', userId)
        .maybeSingle();

    print('DEBUG: dane z profiles: $profileData');

    // Ustaw imię i nazwisko
    if (profileData != null) {
      if (profileData['first_name'] != null) {
        userProfile.imie = profileData['first_name'];
      }
      if (profileData['last_name'] != null) {
        userProfile.nazwisko = profileData['last_name'];
      }
      if (profileData['avatar_url'] != null) {
        userProfile.avatarUrl = profileData['avatar_url'];
      }

      // Załaduj grupy
      final groups = profileData['groups'] as List<dynamic>? ?? [];
      final groupProfiles = groups.map((g) => GroupProfile(
        kodGrupy: g['kod_grupy'] ?? '',
        podgrupa: g['podgrupa'] ?? '',
        kierunek: g['kierunek'] ?? '',
        wydzial: g['wydzial'] ?? '',
        trybStudiow: g['tryb_studiow'] ?? '',
      )).toList();

      userProfile.grupy.value = groupProfiles;

      // Ustaw pierwszą grupę jako aktywną
      if (groupProfiles.isNotEmpty) {
        userProfile.setActiveGroup(
          groupProfiles.first.kodGrupy,
          groupProfiles.first.podgrupa,
        );
      } else {
        // Brak grup - ustaw domyślną
        await _createDefaultGroup(userId);
      }
    } else {
      // Brak profilu - utwórz domyślny
      await _createDefaultProfile(userId);
    }
  } catch (e) {
    print('DEBUG: błąd ładowania profilu: $e');
  }

  print('DEBUG: loadUserProfileFromDb() zakończone');
  print('DEBUG: userProfile.kodGrupy.value = ${userProfile.kodGrupy.value}');
  print('DEBUG: userProfile.podgrupa.value = ${userProfile.podgrupa.value}');
}

Future<void> _createDefaultProfile(String userId) async {
  try {
    await Supabase.instance.client.from('profiles').insert({
      'id': userId,
      'first_name': 'Jan',
      'last_name': 'Kowalski',
      'groups': [],
    });

    await _createDefaultGroup(userId);
  } catch (e) {
    print('DEBUG: błąd tworzenia profilu: $e');
  }
}

Future<void> _createDefaultGroup(String userId) async {
  try {
    // Pobierz info o domyślnej grupie z bazy
    final groupInfo = await Supabase.instance.client
        .from('grupy')
        .select('kierunki(nazwa, wydzial), tryb_studiow')
        .eq('kod_grupy', '24INF-SP')
        .maybeSingle();

    final kierunki = groupInfo?['kierunki'] as Map?;

    final defaultGroup = GroupProfile(
      kodGrupy: '24INF-SP',
      podgrupa: 'A',
      kierunek: kierunki?['nazwa'] ?? 'Informatyka',
      wydzial: kierunki?['wydzial'] ?? 'Wydział Informatyki',
      trybStudiow: groupInfo?['tryb_studiow'] ?? 'Studia stacjonarne',
    );

    userProfile.grupy.value = [defaultGroup];

    // Zapisz w bazie
    await Supabase.instance.client.from('profiles').upsert({
      'id': userId,
      'groups': [{
        'kod_grupy': '24INF-SP',
        'podgrupa': 'A',
        'kierunek': defaultGroup.kierunek,
        'wydzial': defaultGroup.wydzial,
        'tryb_studiow': defaultGroup.trybStudiow,
      }],
    });
  } catch (e) {
    print('DEBUG: błąd tworzenia domyślnej grupy: $e');
  }
}
