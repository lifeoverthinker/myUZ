import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../../screens/grade_details_screen.dart';
import '../../my_uz_icons.dart';

String mapSectionTypeToFullName(String typeCode) {
  switch (typeCode) {
    case 'W+C':
      return 'Wykład + Ćwiczenia';
    case 'W+P':
      return 'Wykład + Projekt';
    case 'P':
      return 'Projekt';
    case 'W+L':
      return 'Wykład + Laboratorium';
    case 'war':
      return 'Warunek';
    case 'Cz':
      return 'Część';
    case 'Sk':
      return 'Składnik';
    case 'WW':
      return 'Wykład i warsztaty';
    case 'R':
      return 'Rezerwacja';
    case 'Ć':
    case 'C':
      return 'Ćwiczenia';
    case 'WĆL':
      return 'Wykład + Ćwiczenia + Laboratorium';
    case 'ZK':
      return 'Zajęcia kliniczne';
    case 'I':
      return 'Inne';
    case 'K':
      return 'Konserwatorium';
    case 'Zp':
      return 'Zajęcia praktyczne';
    case 'T':
      return 'Terenowe';
    case 'Pra':
      return 'Praktyka';
    case 'S':
      return 'Seminarium';
    case 'E':
      return 'Egzamin';
    case 'W':
      return 'Wykład';
    case 'L':
      return 'Laboratorium';
    case 'Pro':
      return 'Proseminarium';
    default:
      return typeCode;
  }
}

class SubjectGradesTab extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final void Function(int subjectIdx)? onAddSection;

  const SubjectGradesTab({Key? key, required this.subjects, this.onAddSection})
    : super(key: key);

  @override
  State createState() => _SubjectGradesTabState();
}

class _SubjectGradesTabState extends State<SubjectGradesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return Center(
        child: Text(
          'Brak przedmiotów',
          style: AppTextStyles.cardTitle(context).copyWith(
            color: kGreyText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        itemCount: widget.subjects.length,
        itemBuilder: (context, subjectIdx) {
          final subject = widget.subjects[subjectIdx];
          final sections = subject['sections'] as List<Map<String, dynamic>>;

          // Średnia bez aktywności
          final gradesForAvg =
              sections
                  .expand((s) => s['grades'] as List<Map<String, dynamic>>)
                  .where((g) => g['value'] != null && g['type'] != 'Aktywność')
                  .map((g) => (g['value'] as num).toDouble())
                  .toList();

          final subjectAvg =
              gradesForAvg.isNotEmpty
                  ? (gradesForAvg.reduce((a, b) => a + b) / gradesForAvg.length)
                  : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        subject['name'],
                        style: AppTextStyles.indexSubjectTitle(
                          context,
                        ).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kMainText,
                        ),
                      ),
                    ),
                    if (subjectAvg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kCardPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Śr. ${subjectAvg.toStringAsFixed(2)}',
                          style: AppTextStyles.indexAverageValue(
                            context,
                          ).copyWith(
                            color: kIndexPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...sections.asMap().entries.map((entry) {
                final sectionIdx = entry.key;
                final section = entry.value;
                final grades = section['grades'] as List<Map<String, dynamic>>;
                final gradesValues =
                    grades
                        .where((g) => g['value'] != null)
                        .map((g) => g['value'].toString())
                        .toList();

                // Średnia sekcji bez aktywności
                final sectionAvgList =
                    grades
                        .where(
                          (g) => g['value'] != null && g['type'] != 'Aktywność',
                        )
                        .map((g) => (g['value'] as num).toDouble())
                        .toList();

                final sectionAvg =
                    sectionAvgList.isNotEmpty
                        ? (sectionAvgList.reduce((a, b) => a + b) /
                            sectionAvgList.length)
                        : null;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => GradeDetailsScreen(
                                subjectName: subject['name'],
                                sectionType: mapSectionTypeToFullName(
                                  section['type'],
                                ),
                                grades:
                                    grades
                                        .where(
                                          (g) =>
                                              g['value'] != null &&
                                              g['type'] != 'Aktywność',
                                        )
                                        .toList(),
                                activityGrades:
                                    grades
                                        .where((g) => g['type'] == 'Aktywność')
                                        .toList(),
                                onAddGrade: (grade) {
                                  setState(() {
                                    grades.add(grade);
                                  });
                                },
                                onEditGrade: (idx, grade) {
                                  setState(() {
                                    final allGrades =
                                        grades
                                            .where(
                                              (g) =>
                                                  g['value'] != null &&
                                                  g['type'] != 'Aktywność',
                                            )
                                            .toList();
                                    if (idx < allGrades.length) {
                                      final originalIdx = grades.indexOf(
                                        allGrades[idx],
                                      );
                                      grades[originalIdx] = grade;
                                    }
                                  });
                                },
                                onDeleteGrade: (idx) {
                                  setState(() {
                                    final allGrades =
                                        grades
                                            .where(
                                              (g) =>
                                                  g['value'] != null &&
                                                  g['type'] != 'Aktywność',
                                            )
                                            .toList();
                                    if (idx < allGrades.length) {
                                      final originalIdx = grades.indexOf(
                                        allGrades[idx],
                                      );
                                      grades.removeAt(originalIdx);
                                    }
                                  });
                                },
                                onAddActivity: (activity) {
                                  setState(() {
                                    grades.add(activity);
                                  });
                                },
                                onEditActivity: (idx, activity) {
                                  setState(() {
                                    final activities =
                                        grades
                                            .where(
                                              (g) => g['type'] == 'Aktywność',
                                            )
                                            .toList();
                                    if (idx < activities.length) {
                                      final originalIdx = grades.indexOf(
                                        activities[idx],
                                      );
                                      grades[originalIdx] = activity;
                                    }
                                  });
                                },
                                onDeleteActivity: (idx) {
                                  setState(() {
                                    final activities =
                                        grades
                                            .where(
                                              (g) => g['type'] == 'Aktywność',
                                            )
                                            .toList();
                                    if (idx < activities.length) {
                                      final originalIdx = grades.indexOf(
                                        activities[idx],
                                      );
                                      grades.removeAt(originalIdx);
                                    }
                                  });
                                },
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 40,
                        right: 32,
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F4F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        height: 64,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Najpierw rodzaj zajęć (grubszy)
                                    Text(
                                      mapSectionTypeToFullName(section['type']),
                                      style: AppTextStyles.cardTitle(
                                        context,
                                      ).copyWith(
                                        fontSize: 15,
                                        color: kMainText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    // Potem oceny (cieńsze)
                                    Text(
                                      gradesValues.isNotEmpty
                                          ? gradesValues.join(', ')
                                          : '+',
                                      style: AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        fontSize: 13,
                                        color: kMainText,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(right: 8, left: 8),
                              child: sectionAvg != null
                                  ? Text(
                                      sectionAvg.toStringAsFixed(2),
                                      style: AppTextStyles.indexAverageValue(context).copyWith(
                                        color: kIndexPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 6, bottom: 18),
                child: GestureDetector(
                  onTap:
                      () => _showAddSectionDialog(
                        context,
                        subjectIdx: subjectIdx,
                      ),
                  child: Text(
                    '+ Dodaj typ zajęć',
                    style: AppTextStyles.cardDescription(context).copyWith(
                      color: kIndexPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSectionDialog(context),
        backgroundColor: kIndexPrimary,
        foregroundColor: Colors.white,
        child: Icon(MyUzIcons.plus, size: 24),
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context, {int? subjectIdx}) async {
    String? selectedSubject;
    if (subjectIdx != null) {
      selectedSubject = widget.subjects[subjectIdx]['name'] as String;
    }

    String? selectedSectionType;
    String? selectedGradeType;
    double? selectedGrade;
    DateTime selectedDate = DateTime.now();
    String description = '';

    final sectionTypes = [
      'Wykład',
      'Ćwiczenia',
      'Laboratorium',
      'Projekt',
      'Seminarium',
    ];
    final gradeTypes = [
      'Kolokwium',
      'Egzamin',
      'Zaliczenie',
      'Projekt',
      'Sprawozdanie',
      'Wejściówka',
      'Aktywność',
    ];

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Dodaj typ zajęć i ocenę',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField(
                            value: selectedSubject,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Przedmiot',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kIndexPrimary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle:
                                  MaterialStateTextStyle.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.focused,
                                    )) {
                                      return AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        color: kIndexPrimary,
                                        fontWeight: FontWeight.w600,
                                      );
                                    }
                                    return AppTextStyles.cardDescription(
                                      context,
                                    ).copyWith(
                                      color: kMainText,
                                      fontWeight: FontWeight.w400,
                                    );
                                  }),
                              labelStyle: MaterialStateTextStyle.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.focused)) {
                                  return AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(
                                    color: kIndexPrimary,
                                    fontWeight: FontWeight.w600,
                                  );
                                }
                                return AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w400,
                                );
                              }),
                            ),
                            items:
                                widget.subjects
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s['name'] as String,
                                        child: Text(
                                          s['name'] as String,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                subjectIdx != null
                                    ? null
                                    : (val) {
                                      setModalState(() {
                                        selectedSubject = val as String?;
                                        selectedSectionType = null;
                                      });
                                    },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField(
                            value: selectedSectionType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Rodzaj zajęć',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kIndexPrimary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle:
                                  MaterialStateTextStyle.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.focused,
                                    )) {
                                      return AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        color: kIndexPrimary,
                                        fontWeight: FontWeight.w600,
                                      );
                                    }
                                    return AppTextStyles.cardDescription(
                                      context,
                                    ).copyWith(
                                      color: kMainText,
                                      fontWeight: FontWeight.w400,
                                    );
                                  }),
                              labelStyle: MaterialStateTextStyle.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.focused)) {
                                  return AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(
                                    color: kIndexPrimary,
                                    fontWeight: FontWeight.w600,
                                  );
                                }
                                return AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w400,
                                );
                              }),
                            ),
                            items:
                                sectionTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setModalState(
                                  () => selectedSectionType = val as String?,
                                ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField(
                            value: selectedGradeType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Typ zaliczenia',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kIndexPrimary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle:
                                  MaterialStateTextStyle.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.focused,
                                    )) {
                                      return AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        color: kIndexPrimary,
                                        fontWeight: FontWeight.w600,
                                      );
                                    }
                                    return AppTextStyles.cardDescription(
                                      context,
                                    ).copyWith(
                                      color: kMainText,
                                      fontWeight: FontWeight.w400,
                                    );
                                  }),
                              labelStyle: MaterialStateTextStyle.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.focused)) {
                                  return AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(
                                    color: kIndexPrimary,
                                    fontWeight: FontWeight.w600,
                                  );
                                }
                                return AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w400,
                                );
                              }),
                            ),
                            items:
                                gradeTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setModalState(() {
                                selectedGradeType = val as String?;
                                if (selectedGradeType == 'Aktywność') {
                                  selectedGrade = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<dynamic>(
                            value:
                                selectedGradeType == 'Aktywność'
                                    ? (selectedGrade == null
                                        ? '+'
                                        : selectedGrade)
                                    : selectedGrade,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Ocena',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kIndexPrimary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle:
                                  MaterialStateTextStyle.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.focused,
                                    )) {
                                      return AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        color: kIndexPrimary,
                                        fontWeight: FontWeight.w600,
                                      );
                                    }
                                    return AppTextStyles.cardDescription(
                                      context,
                                    ).copyWith(
                                      color: kMainText,
                                      fontWeight: FontWeight.w400,
                                    );
                                  }),
                              labelStyle: MaterialStateTextStyle.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.focused)) {
                                  return AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(
                                    color: kIndexPrimary,
                                    fontWeight: FontWeight.w600,
                                  );
                                }
                                return AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w400,
                                );
                              }),
                            ),
                            items:
                                selectedGradeType == 'Aktywność'
                                    ? [
                                      DropdownMenuItem(
                                        value: '+',
                                        child: Text(
                                          '+',
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ]
                                    : [2.0, 3.0, 3.5, 4.0, 4.5, 5.0]
                                        .map(
                                          (val) => DropdownMenuItem(
                                            value: val,
                                            child: Text(
                                              val.toString(),
                                              style:
                                                  AppTextStyles.cardDescription(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            onChanged:
                                selectedGradeType == 'Aktywność'
                                    ? null
                                    : (val) => setModalState(
                                      () => selectedGrade = val as double?,
                                    ),
                          ),
                          const SizedBox(height: 16),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  helpText: 'Wybierz datę oceny',
                                  cancelText: 'Anuluj',
                                  confirmText: 'OK',
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: kIndexPrimary,
                                          onPrimary: Colors.white,
                                          onSurface: kMainText,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: kIndexPrimary,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
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
                                      MyUzIcons.calendar_check,
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
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (val) => description = val,
                            maxLines: 3,
                            style: AppTextStyles.cardDescription(context),
                            decoration: InputDecoration(
                              labelText: 'Opis (opcjonalnie)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kIndexPrimary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              floatingLabelStyle:
                                  MaterialStateTextStyle.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.focused,
                                    )) {
                                      return AppTextStyles.cardDescription(
                                        context,
                                      ).copyWith(
                                        color: kIndexPrimary,
                                        fontWeight: FontWeight.w600,
                                      );
                                    }
                                    return AppTextStyles.cardDescription(
                                      context,
                                    ).copyWith(
                                      color: kMainText,
                                      fontWeight: FontWeight.w400,
                                    );
                                  }),
                              labelStyle: MaterialStateTextStyle.resolveWith((
                                states,
                              ) {
                                if (states.contains(MaterialState.focused)) {
                                  return AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(
                                    color: kIndexPrimary,
                                    fontWeight: FontWeight.w600,
                                  );
                                }
                                return AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(
                                  color: kMainText,
                                  fontWeight: FontWeight.w400,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Anuluj',
                        style: AppTextStyles.cardDescription(
                          context,
                        ).copyWith(color: kGreyText),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedSubject != null &&
                                  selectedSectionType != null &&
                                  (selectedGradeType == 'Aktywność' ||
                                      selectedGrade != null)
                              ? () {
                                final subjectIdxFinal =
                                    subjectIdx ??
                                    widget.subjects.indexWhere(
                                      (s) => s['name'] == selectedSubject,
                                    );
                                final sections =
                                    widget.subjects[subjectIdxFinal]['sections']
                                        as List<Map<String, dynamic>>;
                                final existingSectionIdx = sections.indexWhere(
                                  (sec) => sec['type'] == selectedSectionType,
                                );
                                final gradeData = {
                                  'value':
                                      selectedGradeType == 'Aktywność'
                                          ? '+'
                                          : selectedGrade,
                                  'type': selectedGradeType,
                                  'date': selectedDate,
                                  'description':
                                      description.isNotEmpty
                                          ? description
                                          : null,
                                };
                                setState(() {
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
                              : null,
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
}
