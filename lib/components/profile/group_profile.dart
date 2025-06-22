class GroupProfile {
  final String kodGrupy;
  final String podgrupa;
  final String kierunek;
  final String wydzial;
  final String trybStudiow;

  GroupProfile({
    required this.kodGrupy,
    required this.podgrupa,
    required this.kierunek,
    required this.wydzial,
    required this.trybStudiow,
  });

  Map<String, dynamic> toMap() {
    return {
      'kodGrupy': kodGrupy,
      'podgrupa': podgrupa,
      'kierunek': kierunek,
      'wydzial': wydzial,
      'trybStudiow': trybStudiow,
    };
  }
}