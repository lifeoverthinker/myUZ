class Grupa {
      final int id;
      final String nazwa;
      final int kierunekId;
      final String urlIcs;
      final String? semestr;
      final DateTime? ostatniaAktualizacja;

      Grupa({
        required this.id,
        required this.nazwa,
        required this.kierunekId,
        required this.urlIcs,
        this.semestr,
        this.ostatniaAktualizacja,
      });

      factory Grupa.fromJson(Map<String, dynamic> json) {
        return Grupa(
          id: json['id'],
          nazwa: json['nazwa'],
          kierunekId: json['kierunek_id'],
          urlIcs: json['url_ics'],
          semestr: json['semestr'],
          ostatniaAktualizacja: json['ostatnia_aktualizacja'] != null
              ? DateTime.parse(json['ostatnia_aktualizacja'])
              : null,
        );
      }

      Map<String, dynamic> toJson() {
        return {
          'id': id,
          'nazwa': nazwa,
          'kierunek_id': kierunekId,
          'url_ics': urlIcs,
          'semestr': semestr,
        };
      }
    }