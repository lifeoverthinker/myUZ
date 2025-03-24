class Grupa {
  final int? id;
  final String nazwa;
  final int kierunekId;
  final String urlIcs;

  Grupa({
    this.id,
    required this.nazwa,
    required this.kierunekId,
    required this.urlIcs,
  });

  factory Grupa.fromJson(Map<String, dynamic> json) {
    return Grupa(
      id: json['id'],
      nazwa: json['nazwa'],
      kierunekId: json['kierunek_id'],
      urlIcs: json['url_ics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nazwa': nazwa,
      'kierunek_id': kierunekId,
      'url_ics': urlIcs,
      if (id != null) 'id': id,
    };
  }
}