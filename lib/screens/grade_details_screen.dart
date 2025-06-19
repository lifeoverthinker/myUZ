import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/fonts.dart';
import '../theme/theme.dart';
import '../my_uz_icons.dart';

class GradeDetailsScreen extends StatefulWidget {
  final String subjectName;
  final String sectionType;
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> activityGrades;
  final Function(Map<String, dynamic>) onAddGrade;
  final Function(int, Map<String, dynamic>) onEditGrade;
  final Function(int) onDeleteGrade;
  final Function(Map<String, dynamic>) onAddActivity;
  final Function(int, Map<String, dynamic>) onEditActivity;
  final Function(int) onDeleteActivity;

  const GradeDetailsScreen({
    super.key,
    required this.subjectName,
    required this.sectionType,
    required this.grades,
    required this.activityGrades,
    required this.onAddGrade,
    required this.onEditGrade,
    required this.onDeleteGrade,
    required this.onAddActivity,
    required this.onEditActivity,
    required this.onDeleteActivity,
  });

  @override
  State<GradeDetailsScreen> createState() => _GradeDetailsScreenState();
}

class _GradeDetailsScreenState extends State<GradeDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final sortedGrades = List<Map<String, dynamic>>.from(
      widget.grades,
    )..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final sortedActivity = List<Map<String, dynamic>>.from(
      widget.activityGrades,
    )..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final average =
        widget.grades.isEmpty
            ? null
            : widget.grades
                    .map((g) => g['value'] as num)
                    .reduce((a, b) => a + b) /
                widget.grades.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            MyUzIcons.chevron_left_svgrepo_com,
            color: kMainText,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: AppTextStyles.cardTitle(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kMainText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.sectionType,
              style: AppTextStyles.cardDescription(
                context,
              ).copyWith(fontSize: 14, color: kGreyText),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner ze średnią
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: kCardPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  average?.toStringAsFixed(2) ?? '-',
                  style: AppTextStyles.indexAverageValue(context).copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: kIndexPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Średnia ocen',
                  style: AppTextStyles.cardDescription(
                    context,
                  ).copyWith(color: kIndexPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Lista ocen i aktywności
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sortedGrades.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text(
                        'Oceny',
                        style: AppTextStyles.sectionHeader(
                          context,
                        ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: sortedGrades.length,
                      separatorBuilder:
                          (context, i) => const Divider(
                            height: 1,
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      itemBuilder: (context, idx) {
                        final grade = sortedGrades[idx];
                        return _buildGradeRow(grade, idx);
                      },
                    ),
                  ] else
                    _buildEmptyState('Brak ocen w tym przedmiocie'),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Aktywność',
                      style: AppTextStyles.sectionHeader(
                        context,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (sortedActivity.isEmpty)
                    _buildEmptyState('Brak aktywności'),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: sortedActivity.length,
                    separatorBuilder:
                        (context, i) => const Divider(
                          height: 1,
                          color: Color(0xFFE0E0E0),
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                    itemBuilder: (context, idx) {
                      final activity = sortedActivity[idx];
                      return _buildActivityRow(activity, idx);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(isActivity: true),
        backgroundColor: kIndexPrimary,
        foregroundColor: Colors.white,
        child: Icon(MyUzIcons.plus, size: 24),
        tooltip: 'Dodaj ocenę/aktywność',
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> grade, int index) {
    final date = grade['date'] as DateTime? ?? DateTime.now();
    final value = grade['value'] as num;
    final type = grade['type'] as String? ?? 'Ocena';
    final description = grade['description'] as String?;
    return InkWell(
      onTap: () => _showAddModal(grade: grade, gradeIndex: index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kCardPurple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  value.toString(),
                  style: AppTextStyles.indexGrade(context).copyWith(
                    color: kIndexPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: AppTextStyles.cardTitle(context).copyWith(
                      fontSize: 15,
                      color: kMainText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: AppTextStyles.cardDescription(
                        context,
                      ).copyWith(color: kCardDesc, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: AppTextStyles.cardDescription(
                context,
              ).copyWith(color: kGreyText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity, int index) {
    final date = activity['date'] as DateTime? ?? DateTime.now();
    final type = activity['type'] as String? ?? 'Aktywność';
    final description = activity['description'] as String?;
    return InkWell(
      onTap: () => _showAddModal(activity: activity, activityIndex: index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kCardGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  '+',
                  style: AppTextStyles.indexGrade(context).copyWith(
                    color: const Color(0xFF388E3C),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: AppTextStyles.cardTitle(context).copyWith(
                      fontSize: 15,
                      color: kMainText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: AppTextStyles.cardDescription(
                        context,
                      ).copyWith(color: kCardDesc, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: AppTextStyles.cardDescription(
                context,
              ).copyWith(color: kGreyText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTextStyles.cardDescription(
          context,
        ).copyWith(color: kGreyText),
      ),
    );
  }

  void _showAddModal({
    Map<String, dynamic>? grade,
    int? gradeIndex,
    Map<String, dynamic>? activity,
    int? activityIndex,
    bool isActivity = false,
  }) {
    final isEditingGrade = grade != null;
    final isEditingActivity = activity != null;
    String? selectedType =
        isActivity
            ? 'Aktywność'
            : isEditingGrade
            ? grade!['type']
            : isEditingActivity
            ? activity!['type']
            : null;
    double? selectedValue =
        isEditingGrade ? (grade!['value'] as num?)?.toDouble() : null;
    DateTime selectedDate =
        isEditingGrade
            ? grade!['date']
            : isEditingActivity
            ? activity!['date']
            : DateTime.now();
    String description =
        isEditingGrade
            ? (grade!['description'] ?? '')
            : (isEditingActivity ? (activity!['description'] ?? '') : '');

    final gradeTypes = [
      'Kolokwium',
      'Egzamin',
      'Zaliczenie',
      'Projekt',
      'Sprawozdanie',
      'Wejściówka',
      'Aktywność',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateModal) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  title: Text(
                    isEditingGrade
                        ? 'Edytuj ocenę'
                        : isEditingActivity
                        ? 'Edytuj aktywność'
                        : 'Dodaj ${isActivity ? 'aktywn.' : 'ocenę'}',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 18),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: 'Typ',
                            labelStyle: TextStyle(color: kMainText),
                            floatingLabelStyle: TextStyle(color: kIndexPrimary),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items:
                              gradeTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: AppTextStyles.cardDescription(
                                          context,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setStateModal(() {
                                selectedType = val;
                                if (val == 'Aktywność') selectedValue = null;
                              }),
                        ),
                        const SizedBox(height: 16),
                        if (selectedType != 'Aktywność')
                          DropdownButtonFormField<double>(
                            value: selectedValue,
                            decoration: InputDecoration(
                              labelText: 'Ocena',
                              labelStyle: TextStyle(color: kMainText),
                              floatingLabelStyle: TextStyle(
                                color: kIndexPrimary,
                              ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items:
                                [2.0, 3.0, 3.5, 4.0, 4.5, 5.0]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(
                                          v.toString(),
                                          style: AppTextStyles.cardDescription(
                                            context,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) =>
                                    setStateModal(() => selectedValue = val),
                          ),
                        if (selectedType != 'Aktywność')
                          const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder:
                                  (context, child) => Theme(
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
                                  ),
                            );
                            if (picked != null)
                              setStateModal(() => selectedDate = picked);
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
                                  DateFormat('dd.MM.yyyy').format(selectedDate),
                                  style: AppTextStyles.cardDescription(
                                    context,
                                  ).copyWith(color: kMainText, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: TextEditingController(text: description),
                          onChanged: (val) => description = val,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Opis (opcjonalnie)',
                            labelStyle: TextStyle(color: kMainText),
                            floatingLabelStyle: TextStyle(color: kIndexPrimary),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
                    if (isEditingGrade || isEditingActivity)
                      TextButton(
                        onPressed: () {
                          if (isEditingGrade) {
                            widget.onDeleteGrade(gradeIndex!);
                          } else {
                            widget.onDeleteActivity(activityIndex!);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Usuń',
                          style: AppTextStyles.cardDescription(
                            context,
                          ).copyWith(color: kCardRed),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            selectedType != null &&
                                    (selectedType == 'Aktywność' ||
                                        selectedValue != null)
                                ? () {
                                  final data = {
                                    'value':
                                        selectedType == 'Aktywność'
                                            ? '+'
                                            : selectedValue,
                                    'type': selectedType,
                                    'date': selectedDate,
                                    'description':
                                        description.isNotEmpty
                                            ? description
                                            : null,
                                  };
                                  if (isEditingGrade) {
                                    widget.onEditGrade(gradeIndex!, data);
                                  } else if (isEditingActivity) {
                                    widget.onEditActivity(activityIndex!, data);
                                  } else if (isActivity) {
                                    widget.onAddActivity(data);
                                  } else {
                                    widget.onAddGrade(data);
                                  }
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kIndexPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          isEditingGrade || isEditingActivity
                              ? 'Zapisz'
                              : 'Dodaj',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
