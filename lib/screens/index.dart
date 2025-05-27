import 'package:flutter/material.dart';

class IndexScreen extends StatelessWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Przykładowe dane lokalne
    final double average = 4.5;
    final List<Map<String, dynamic>> subjects = [
      {'name': 'Przedmiot', 'grade': 5.0},
      {'name': 'Przedmiot', 'grade': 5.0},
      {'name': 'Przedmiot', 'grade': 5.0},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEFFAFF),
      body: Center(
        child: Container(
          width: 360,
          height: 780,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Stack(
            children: [
              // Fake status bar
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 360,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '9:30',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                          letterSpacing: 0.14,
                        ),
                      ),
                      SizedBox(width: 17, height: 17),
                      SizedBox(width: 8, height: 15),
                    ],
                  ),
                ),
              ),
              // Tytuł
              const Positioned(
                left: 16,
                top: 58,
                child: SizedBox(
                  width: 328,
                  child: Text(
                    'Indeks',
                    style: TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 2,
                    ),
                  ),
                ),
              ),
              // Zakładki
              Positioned(
                left: 16,
                top: 124,
                child: Row(
                  children: [
                    // "Oceny" aktywna
                    Container(
                      height: 32,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE8DEF8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Center(
                          child: Text(
                            'Oceny',
                            style: TextStyle(
                              color: Color(0xFF1D192B),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // "Nieobecności"
                    Container(
                      height: 32,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Color(0xFF79747E),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Center(
                          child: Text(
                            'Nieobecności',
                            style: TextStyle(
                              color: Color(0xFF49454F),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // "Stypendium"
                    Container(
                      height: 32,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Color(0xFF79747E),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Center(
                          child: Text(
                            'Stypendium',
                            style: TextStyle(
                              color: Color(0xFF49454F),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // "Średnia ocen z ostatniego semestru"
              const Positioned(
                left: 16,
                top: 192,
                child: SizedBox(
                  width: 252,
                  child: Text(
                    'Średnia ocen z ostatniego semestru',
                    style: TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
              // Średnia value
              Positioned(
                left: 308,
                top: 199,
                child: Text(
                  average.toStringAsFixed(1).replaceAll('.', ','),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 23,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.04,
                  ),
                ),
              ),
              // Lista przedmiotów i ocen (statyczne pozycje jak w makiecie)
              Positioned(
                left: 16,
                top: 266,
                child: Container(
                  width: 328,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 252,
                        child: Text(
                          subjects[0]['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                      Text(
                        (subjects[0]['grade'] as num).toDouble().toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 305,
                child: Container(
                  width: 328,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 252,
                        child: Text(
                          subjects[1]['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                      Text(
                        (subjects[1]['grade'] as num).toDouble().toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 344,
                child: Container(
                  width: 328,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 252,
                        child: Text(
                          subjects[2]['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                      Text(
                        (subjects[2]['grade'] as num).toDouble().toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Dolny pasek nawigacji
              Positioned(
                left: 0,
                top: 708,
                child: Container(
                  width: 360,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: Color(0xFFEDE6F3),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            _NavBarItem(label: 'Główna', active: false),
                            _NavBarItem(label: 'Kalendarz', active: false),
                            _NavBarItem(label: 'Indeks', active: true),
                            _NavBarItem(label: 'Konto', active: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String label;
  final bool active;
  const _NavBarItem({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: const SizedBox.shrink(),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? const Color(0xFF381E72) : const Color(0xFF787579),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
