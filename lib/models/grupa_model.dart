class Grupa {
  final int id;
  final String nazwa;
  final int? kierunekId;
  final String urlIcs;
  final DateTime? ostatniaAktualizacja;

  Grupa({
    required this.id,
    required this.nazwa,
    this.kierunekId,
    required this.urlIcs,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nazwa': nazwa,
    'kierunek_id': kierunekId,
    'url_ics': urlIcs,
  };
}
