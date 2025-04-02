class PlanNauczyciela {
  final String uid;
  final int nauczycielId;
  final DateTime od;
  final DateTime do_;
  final String przedmiot;
  final String? rz;
  final String? miejsce;
  final String? terminy;
  final DateTime? ostatniaAktualizacja;

  PlanNauczyciela({
    required this.uid,
    required this.nauczycielId,
    required this.od,
    required this.do_,
    required this.przedmiot,
    this.rz,
    this.miejsce,
    this.terminy,
    this.ostatniaAktualizacja,
  });

  Map<String, dynamic> toJson() => {
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
