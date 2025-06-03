import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../components/index/SubjectGradesTab.dart';
import '../components/index/AbsencesTab.dart';
import '../components/index/TabBarRow.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  int _tabIndex = 0;

  // Przykładowe dane – podmień na swoje źródło
  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Elementy sztucznej inteligencji',
      'sections': [
        {
          'type': 'Wykład',
          'grades': [
            {'value': 4.5, 'type': 'Kolokwium', 'date': DateTime(2025, 3, 20)},
            {'value': 5.0, 'type': 'Wejściówka', 'date': DateTime(2025, 3, 27)},
          ],
        },
        {
          'type': 'Laboratorium',
          'grades': [
            {
              'value': 4.0,
              'type': 'Sprawozdanie',
              'date': DateTime(2025, 4, 2),
            },
          ],
        },
      ],
    },
    {
      'name': 'Analiza matematyczna',
      'sections': [
        {'type': 'Wykład', 'grades': []},
        {'type': 'Ćwiczenia', 'grades': []},
      ],
    },
  ];

  final List<Map<String, dynamic>> _absences = [
    {'subject': 'Elementy sztucznej inteligencji', 'count': 2},
    {'subject': 'Analiza matematyczna', 'count': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tytuł
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text('Indeks', style: AppTextStyles.indexTitle(context)),
            ),
            // Zakładki
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TabBarRow(
                selectedIndex: _tabIndex,
                labels: ['Oceny', 'Nieobecności'],
                onTabChanged: (idx) => setState(() => _tabIndex = idx),
              ),
            ),
            // Zawartość zakładek
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  SubjectGradesTab(subjects: _subjects),
                  AbsencesTab(absences: _absences),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
