import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../my_uz_icons.dart';
import '../theme/fonts.dart';
import '../theme/theme.dart';
import '../components/index/SubjectGradesTab.dart';
import '../components/index/AbsencesTab.dart';
import '../components/index/TabBarRow.dart';
import '../services/supabase_service.dart';
import '../components/profile/user_profile.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _absences = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    userProfile.kodGrupy.addListener(_onKodGrupyChanged);
    if (userProfile.kodGrupy.value.isNotEmpty) {
      _fetchSubjects(userProfile.kodGrupy.value);
    }
  }

  @override
  void dispose() {
    userProfile.kodGrupy.removeListener(_onKodGrupyChanged);
    super.dispose();
  }

  void _onKodGrupyChanged() {
    final kod = userProfile.kodGrupy.value;
    if (kod.isNotEmpty) {
      _fetchSubjects(kod);
    } else {
      setState(() {
        _subjects = [];
        _absences = [];
      });
    }
  }

  // Pobieranie przedmiotów i synchronizacja absences
  Future<void> _fetchSubjects(String kodGrupy) async {
    setState(() => _loading = true);
    final subjects = await _supabaseService.fetchSubjectsForGroup(kodGrupy);
    setState(() {
      _subjects =
          subjects
              .map(
                (name) => {'name': name, 'sections': <Map<String, dynamic>>[]},
              )
              .toList();

      // Synchronizuj absences z listą przedmiotów
      _absences =
          _absences.where((a) => subjects.contains(a['subject'])).toList();

      // Dodaj brakujące przedmioty do absences
      for (String subject in subjects) {
        if (!_absences.any((a) => a['subject'] == subject)) {
          _absences.add({
            'subject': subject,
            'sections': [
              {'type': 'Wykład', 'absences': <Map<String, dynamic>>[]},
              {'type': 'Ćwiczenia', 'absences': <Map<String, dynamic>>[]},
              {'type': 'Laboratorium', 'absences': <Map<String, dynamic>>[]},
              {'type': 'Projekt', 'absences': <Map<String, dynamic>>[]},
              {'type': 'Seminarium', 'absences': <Map<String, dynamic>>[]},
            ],
            'limit': 2,
          });
        }
      }
      _loading = false;
    });
  }

  // Dodawanie nieobecności: modal z wyborem daty
  void _addAbsence(int subjectIdx, int sectionIdx) {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Dodaj nieobecność',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        helpText: 'Wybierz datę nieobecności',
                        cancelText: 'Anuluj',
                        confirmText: 'OK',
                      );
                      if (picked != null)
                        setModalState(() => selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: kCardBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: kIndexPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd.MM.yyyy').format(selectedDate),
                            style: AppTextStyles.cardDescription(
                              context,
                            ).copyWith(color: kMainText, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Anuluj', style: TextStyle(color: kGreyText)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          (_absences[subjectIdx]['sections'][sectionIdx]['absences']
                                  as List)
                              .add({'date': selectedDate});
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kIndexPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Dodaj',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  // Dodawanie typu zajęć i ocen (zgodnie z Figma) – uproszczone, analogicznie jak w Twoim kodzie
  Future<void> _addSection(int subjectIdx) async {
    final kodGrupy = userProfile.kodGrupy.value;
    List<String> sectionTypes = [];
    try {
      sectionTypes =
          await _supabaseService.fetchUniqueSectionTypesForGroup(kodGrupy) ??
          [];
      if (sectionTypes.isEmpty) {
        sectionTypes = [
          'Wykład',
          'Ćwiczenia',
          'Laboratorium',
          'Projekt',
          'Seminarium',
        ];
      }
    } catch (e) {
      sectionTypes = [
        'Wykład',
        'Ćwiczenia',
        'Laboratorium',
        'Projekt',
        'Seminarium',
      ];
    }

    final List<String> gradeTypes = [
      'Kolokwium',
      'Egzamin',
      'Zaliczenie',
      'Projekt',
      'Sprawozdanie',
      'Wejściówka',
      'Aktywność',
    ];

    String? selectedSectionType;
    String? selectedGradeType;
    double? selectedGrade;
    DateTime selectedDate = DateTime.now();
    String description = '';
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nagłówek
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dodaj ocenę',
                                style: AppTextStyles.cardTitle(
                                  context,
                                ).copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: kMainText,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: kGreyText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Formularz
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedSectionType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Rodzaj zajęć',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      sectionTypes
                                          .map(
                                            (type) => DropdownMenuItem<String>(
                                              value: type,
                                              child: Text(
                                                type,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setModalState(
                                        () => selectedSectionType = val,
                                      ),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Wybierz rodzaj zajęć'
                                              : null,
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: selectedGradeType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Typ zaliczenia (opcjonalnie)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      gradeTypes
                                          .map(
                                            (type) => DropdownMenuItem<String>(
                                              value: type,
                                              child: Text(
                                                type,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setModalState(
                                        () => selectedGradeType = val,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<double>(
                                  value: selectedGrade,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Ocena (opcjonalnie)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      [2.0, 3.0, 3.5, 4.0, 4.5, 5.0]
                                          .map(
                                            (val) => DropdownMenuItem<double>(
                                              value: val,
                                              child: Text(val.toString()),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setModalState(
                                        () => selectedGrade = val,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null)
                                      setModalState(
                                        () => selectedDate = picked,
                                      );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: kCardBorder),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: kIndexPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          DateFormat(
                                            'dd.MM.yyyy',
                                          ).format(selectedDate),
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ).copyWith(
                                            color: kMainText,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  onChanged:
                                      (val) => setModalState(
                                        () => description = val,
                                      ),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Opis (opcjonalnie)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Przycisk dodawania
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  final subject = _subjects[subjectIdx];
                                  final sections =
                                      subject['sections']
                                          as List<Map<String, dynamic>>;
                                  final existingSectionIdx = sections
                                      .indexWhere(
                                        (sec) =>
                                            sec['type'] == selectedSectionType,
                                      );
                                  final gradeData = {
                                    'value': selectedGrade,
                                    'type': selectedGradeType,
                                    'date': selectedDate,
                                    'description':
                                        description.isNotEmpty
                                            ? description
                                            : null,
                                  };
                                  if (existingSectionIdx != -1) {
                                    (sections[existingSectionIdx]['grades']
                                            as List)
                                        .add(gradeData);
                                  } else {
                                    sections.add({
                                      'type': selectedSectionType,
                                      'grades': [gradeData],
                                    });
                                  }
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kIndexPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Dodaj',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupIsSelected = userProfile.kodGrupy.value.isNotEmpty;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Indeks',
                style: AppTextStyles.indexTitle(context).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kMainText,
                ),
              ),
            ),
            // TabBar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: TabBarRow(
                selectedIndex: _tabIndex,
                labels: const ['Oceny', 'Nieobecności'],
                onTabChanged: (idx) => setState(() => _tabIndex = idx),
              ),
            ),
            // Zawartość
            // Zawartość - fragment w build method
            // Zawartość - fragment w build method
            Expanded(
              child:
                  groupIsSelected
                      ? (_loading
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(kIndexPrimary),
                            ),
                          )
                          : IndexedStack(
                            index: _tabIndex,
                            children: [
                              SubjectGradesTab(
                                subjects: _subjects,
                                onAddSection: _addSection,
                              ),
                              AbsencesTab(absences: _absences),
                            ],
                          ))
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Ikona bez kwadratowego tła
                            Icon(
                              MyUzIcons.graduation_hat,
                              color: kIndexPrimary,
                              size: 80,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Wybierz grupę w ustawieniach',
                              style: AppTextStyles.cardTitle(context).copyWith(
                                color: kMainText,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aby wyświetlić swój indeks, przejdź do profilu\ni ustaw swoją grupę studiów',
                              style: AppTextStyles.cardDescription(
                                context,
                              ).copyWith(color: kGreyText, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
