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

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'url_plan': urlPlan,
    'url_id': urlId,
    'nazwa': nazwa,
  };
}
