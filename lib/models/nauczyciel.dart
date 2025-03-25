class Nauczyciel {
  final int? id;
  final String? urlId;
  final String urlPlan;
  final String? nazwa;
  final String? email;
  final DateTime? ostatniaAktualizacja;

  Nauczyciel({
    this.id,
    this.urlId,
    required this.urlPlan,
    this.nazwa,
    this.email,
    this.ostatniaAktualizacja,
  });

  Nauczyciel copyWith({
    int? id,
    String? urlId,
    String? urlPlan,
    String? nazwa,
    String? email,
    DateTime? ostatniaAktualizacja,
  }) {
    return Nauczyciel(
      id: id ?? this.id,
      urlId: urlId ?? this.urlId,
      urlPlan: urlPlan ?? this.urlPlan,
      nazwa: nazwa ?? this.nazwa,
      email: email ?? this.email,
      ostatniaAktualizacja: ostatniaAktualizacja ?? this.ostatniaAktualizacja,
    );
  }

  Map<String, dynamic> toJson() => {
        'url_id': urlId,
        'url_plan': urlPlan,
        'nazwa': nazwa,
        'email': email,
      };

  factory Nauczyciel.fromJson(Map<String, dynamic> json) => Nauczyciel(
        id: json['id'],
        urlId: json['url_id'],
        urlPlan: json['url_plan'],
        nazwa: json['nazwa'],
        email: json['email'],
        ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
            ? DateTime.parse(json['ostatnia_aktualizacja'])
            : null,
      );
}
