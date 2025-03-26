class Nauczyciel {
  final int id;
  final String? email;
  final String urlPlan;
  final DateTime? ostatniaAktualizacja;
  final String? urlId;
  final String? nazwa;

  Nauczyciel({
    required this.id,
    this.email,
    required this.urlPlan,
    this.ostatniaAktualizacja,
    this.urlId,
    this.nazwa,
  });

  factory Nauczyciel.fromJson(Map<String, dynamic> json) {
    return Nauczyciel(
      id: json['id'] as int,
      email: json['email'] as String?,
      urlPlan: json['url_plan'] as String,
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
      urlId: json['url_id'] as String?,
      nazwa: json['nazwa'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'url_plan': urlPlan,
      'ostatnia_aktualizacja': ostatniaAktualizacja?.toIso8601String(),
      'url_id': urlId,
      'nazwa': nazwa,
    };
  }
}
