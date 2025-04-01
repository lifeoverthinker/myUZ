class Nauczyciel {
  final int id;
  final String? email;
  final String urlPlan;
  final String? urlId;
  final String? nazwa;
  final DateTime? ostatniaAktualizacja;

  Nauczyciel({
    required this.id,
    this.email,
    required this.urlPlan,
    this.urlId,
    this.nazwa,
    this.ostatniaAktualizacja,
  });

  factory Nauczyciel.fromJson(Map<String, dynamic> json) {
    return Nauczyciel(
      id: json['id'],
      email: json['email'],
      urlPlan: json['url_plan'],
      urlId: json['url_id'],
      nazwa: json['nazwa'],
      ostatniaAktualizacja: DateTime.parse(json['ostatnia_aktualizacja']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'url_plan': urlPlan,
      'url_id': urlId,
      'nazwa': nazwa,
    };
  }
}