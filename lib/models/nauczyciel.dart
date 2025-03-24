class Nauczyciel {
  final int? id;
  final String pelneImieNazwisko;
  final String email;
  final int wydzialId;
  final String urlPlan;
  final DateTime? ostatniaAktualizacja;

  Nauczyciel({
    this.id,
    required this.pelneImieNazwisko,
    required this.email,
    required this.wydzialId,
    required this.urlPlan,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'pelne_imie_nazwisko': pelneImieNazwisko,
      'email': email,
      'wydzial_id': wydzialId,
      'url_plan': urlPlan,
    };

    // Dodaj id tylko jeśli nie jest null (przy aktualizacji)
    if (id != null) {
      json['id'] = id;
    }

    // Dodaj datę aktualizacji jeśli jest
    if (ostatniaAktualizacja != null) {
      json['ostatnia_aktualizacja'] = ostatniaAktualizacja!.toIso8601String();
    }

    return json;
  }

  factory Nauczyciel.fromJson(Map<String, dynamic> json) {
    return Nauczyciel(
      id: json['id'],
      pelneImieNazwisko: json['pelne_imie_nazwisko'],
      email: json['email'],
      wydzialId: json['wydzial_id'],
      urlPlan: json['url_plan'],
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
    );
  }
}