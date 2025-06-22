import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_profile.dart';
import '../../theme/theme.dart';

class UserProfile {
  String imie;
  String nazwisko;
  String? avatarUrl;
  String id;

  Map<String, int> subjectColorMapping = {
    'W': 0,
    'C': 1,
    'L': 2,
    'P': 3,
    'S': 4,
  };

  int selectedThemeColor = 0;

  final ValueNotifier<String> initialsNotifier = ValueNotifier<String>('');
  final ValueNotifier<List<GroupProfile>> grupy = ValueNotifier<List<GroupProfile>>([]);
  final ValueNotifier<String> kodGrupy = ValueNotifier<String>('');
  final ValueNotifier<String> podgrupa = ValueNotifier<String>('');

  UserProfile({
    this.imie = 'Jan',
    this.nazwisko = 'Kowalski',
    this.avatarUrl,
    String? id,
  }) : id = id ?? Supabase.instance.client.auth.currentUser?.id ?? '' {
    _updateInitials();
  }

  String get initials {
    final i = imie.isNotEmpty ? imie[0] : '';
    final n = nazwisko.isNotEmpty ? nazwisko[0] : '';
    return '$i$n';
  }

  void _updateInitials() {
    initialsNotifier.value = initials;
  }

  String get fullName => '$imie $nazwisko';

  void setFullName(String name) {
    final parts = name.split(' ');
    imie = parts.first;
    nazwisko = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _updateInitials();
  }

  GroupProfile? get activeGroup {
    if (grupy.value.isEmpty) return null;
    return grupy.value.firstWhere(
      (g) => g.kodGrupy == kodGrupy.value && g.podgrupa == podgrupa.value,
      orElse: () => grupy.value.first,
    );
  }

  String? get wydzial => activeGroup?.wydzial;
  String? get kierunek => activeGroup?.kierunek;

  Color getColorForSubjectType(String rz) {
    final idx = subjectColorMapping[rz.toUpperCase()] ?? 0;
    return kMaterialPalette[idx % kMaterialPalette.length];
  }

  void setColorForSubjectType(String rz, int idx) {
    subjectColorMapping[rz.toUpperCase()] = idx;
  }

  void setActiveGroup(String kod, String? pod) {
    kodGrupy.value = kod;
    podgrupa.value = pod ?? '';
  }

  void setGrupa(String kod) {
    kodGrupy.value = kod;
  }

  void setPodgrupa(String pod) {
    podgrupa.value = pod;
  }

  Future addGroup(String kod, String? pod) async {
    try {
      final groupInfo = await Supabase.instance.client
          .from('grupy')
          .select('kierunki(nazwa, wydzial), tryb_studiow')
          .eq('kod_grupy', kod)
          .single();

      final kierunki = groupInfo['kierunki'] as Map?;
      final newGroup = GroupProfile(
        kodGrupy: kod,
        podgrupa: pod ?? '',
        kierunek: kierunki?['nazwa'] ?? '',
        wydzial: kierunki?['wydzial'] ?? '',
        trybStudiow: groupInfo['tryb_studiow'] ?? '',
      );

      if (!grupy.value.any((g) => g.kodGrupy == kod && g.podgrupa == (pod ?? ''))) {
        grupy.value = List.from(grupy.value)..add(newGroup);
        if (id.isNotEmpty) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': id,
            'groups': grupy.value.map((g) => g.toMap()).toList(),
          });
        }
        if (grupy.value.length == 1) {
          setActiveGroup(kod, pod);
        }
      }
    } catch (e) {
      print('Błąd dodawania grupy: $e');
    }
  }

  Future removeGroup(String kod, String? pod) async {
    grupy.value = grupy.value.where((g) => g.kodGrupy != kod || g.podgrupa != (pod ?? '')).toList();
    if (grupy.value.isNotEmpty) {
      setActiveGroup(grupy.value.first.kodGrupy, grupy.value.first.podgrupa);
    } else {
      setActiveGroup('', '');
    }
    if (id.isNotEmpty) {
      await Supabase.instance.client.from('profiles').upsert({
        'id': id,
        'groups': grupy.value.map((g) => g.toMap()).toList(),
      });
    }
  }

  Future updateName(String fullName) async {
    setFullName(fullName);
    if (id.isNotEmpty) {
      await Supabase.instance.client.from('profiles').upsert({
        'id': id,
        'first_name': imie,
        'last_name': nazwisko,
        'avatar_url': avatarUrl,
      });
    }
  }

  GroupProfile? getGroupInfo(String kod, String? pod) {
    try {
      return grupy.value.firstWhere(
        (g) => g.kodGrupy == kod && g.podgrupa == (pod ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}

final userProfile = UserProfile();