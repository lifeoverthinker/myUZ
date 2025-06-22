import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'absence_details_screen.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
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

class AbsencesTab extends StatefulWidget {
  final List<Map<String, dynamic>> absences;

  const AbsencesTab({super.key, required this.absences});

  @override
  State<AbsencesTab> createState() => _AbsencesTabState();
}

class _AbsencesTabState extends State<AbsencesTab> {
  @override
  Widget build(BuildContext context) {
    final absencesToShow = <Map<String, dynamic>>[];
    for (var subject in widget.absences) {
      final subjectName = subject['subject'];
      final limit = subject['limit'] ?? 2;
      final sections = subject['sections'] as List<Map<String, dynamic>>? ?? [];
      for (var section in sections) {
        final abs = section['absences'] as List<Map<String, dynamic>>? ?? [];
        if (abs.isNotEmpty) {
          absencesToShow.add({
            'subject': subjectName,
            'type': section['type'],
            'absences': abs,
            'limit': limit,
          });
        }
      }
    }

    return Scaffold(
      body:
          absencesToShow.isEmpty
              ? Center(
                child: Text(
                  'Brak nieobecności',
                  style: AppTextStyles.cardTitle(context).copyWith(
                    color: kGreyText,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                itemCount: absencesToShow.length,
                itemBuilder: (context, idx) {
                  final item = absencesToShow[idx];
                  final subject = item['subject'];
                  final type = item['type'];
                  final abs = item['absences'] as List<Map<String, dynamic>>;
                  final limit = item['limit'];
                  final isOverLimit = abs.length >= limit;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (idx == 0 ||
                          absencesToShow[idx - 1]['subject'] != subject)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 8,
                          ),
                          child: Text(
                            subject,
                            style: AppTextStyles.indexSubjectTitle(
                              context,
                            ).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: kMainText,
                            ),
                          ),
                        ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => AbsenceDetailsScreen(
                                      subjectName: subject,
                                      sectionType: mapSectionTypeToFullName(
                                        type,
                                      ),
                                      absences: abs,
                                      limit: limit,
                                      onAddAbsence: (newAbs) {
                                        setState(() {
                                          abs.add(newAbs);
                                        });
                                      },
                                      onEditAbsence: (i, updated) {
                                        setState(() {
                                          abs[i] = updated;
                                        });
                                      },
                                      onDeleteAbsence: (i) {
                                        setState(() {
                                          abs.removeAt(i);
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
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 0,
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        mapSectionTypeToFullName(type),
                                        style: AppTextStyles.cardDescription(
                                          context,
                                        ).copyWith(
                                          color: kMainText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(right: 0),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      '${abs.length}/$limit',
                                      style: AppTextStyles.indexGrade(
                                        context,
                                      ).copyWith(
                                        color:
                                            isOverLimit
                                                ? kCardRed
                                                : kIndexPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAbsenceDialog(context),
        backgroundColor: kIndexPrimary,
        foregroundColor: Colors.white,
        child: Icon(MyUzIcons.plus, size: 24),
      ),
    );
  }

  void _showAddAbsenceDialog(BuildContext context) async {
    String? selectedSubject;
    String? selectedSection;
    DateTime selectedDate = DateTime.now();

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
                    'Dodaj nieobecność',
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
                          DropdownButtonFormField<String>(
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
                                widget.absences
                                    .map<DropdownMenuItem<String>>(
                                      (s) => DropdownMenuItem<String>(
                                        value: s['subject'] as String,
                                        child: Text(
                                          s['subject'] as String,
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
                                selectedSubject = val;
                                selectedSection = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedSection,
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
                                selectedSubject == null
                                    ? []
                                    : (widget.absences.firstWhere(
                                              (s) =>
                                                  s['subject'] ==
                                                  selectedSubject,
                                            )['sections']
                                            as List)
                                        .map<DropdownMenuItem<String>>(
                                          (sec) => DropdownMenuItem<String>(
                                            value: sec['type'] as String,
                                            child: Text(
                                              mapSectionTypeToFullName(
                                                sec['type'] as String,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  AppTextStyles.cardDescription(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            onChanged:
                                (val) =>
                                    setModalState(() => selectedSection = val),
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
                          selectedSubject != null && selectedSection != null
                              ? () {
                                final subjectIdx = widget.absences.indexWhere(
                                  (s) => s['subject'] == selectedSubject,
                                );
                                final sectionIdx = (widget
                                            .absences[subjectIdx]['sections']
                                        as List)
                                    .indexWhere(
                                      (sec) => sec['type'] == selectedSection,
                                    );
                                setState(() {
                                  (widget.absences[subjectIdx]['sections'][sectionIdx]['absences']
                                          as List)
                                      .add({'date': selectedDate});
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
