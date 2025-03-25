class PlanNauczyciela {
  final String? uid;
  final int? nauczycielId;
  final DateTime od;
  final DateTime do_;
  final String przedmiot;
  final String? rz;
  final String? miejsce;
  final String? terminy;
  final DateTime? ostatniaAktualizacja;

  PlanNauczyciela({
    this.uid,
    this.nauczycielId,
    required this.od,
    required this.do_,
    required this.przedmiot,
    this.rz,
    this.miejsce,
    this.terminy,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nauczyciel_id': nauczycielId,
      'od': od.toIso8601String(),
      'do': do_.toIso8601String(),
      'przedmiot': przedmiot,
      'rz': rz,
      'miejsce': miejsce,
      'terminy': terminy,
    };
  }

  factory PlanNauczyciela.fromJson(Map<String, dynamic> json) {
    return PlanNauczyciela(
      uid: json['uid'],
      nauczycielId: json['nauczyciel_id'],
      od: DateTime.parse(json['od']),
      do_: DateTime.parse(json['do']),
      przedmiot: json['przedmiot'],
      rz: json['rz'],
      miejsce: json['miejsce'],
      terminy: json['terminy'],
      ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
          ? DateTime.parse(json['ostatnia_aktualizacja'])
          : null,
    );
  }
}
