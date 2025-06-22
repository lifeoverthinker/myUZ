import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../../my_uz_icons.dart';

class AbsenceDetailsScreen extends StatefulWidget {
  final String subjectName;
  final String sectionType;
  final List<Map<String, dynamic>> absences;
  final int limit;
  final Function(Map<String, dynamic>) onAddAbsence;
  final Function(int, Map<String, dynamic>) onEditAbsence;
  final Function(int) onDeleteAbsence;

  const AbsenceDetailsScreen({
    super.key,
    required this.subjectName,
    required this.sectionType,
    required this.absences,
    required this.limit,
    required this.onAddAbsence,
    required this.onEditAbsence,
    required this.onDeleteAbsence,
  });

  @override
  State<AbsenceDetailsScreen> createState() => _AbsenceDetailsScreenState();
}

class _AbsenceDetailsScreenState extends State<AbsenceDetailsScreen> {
  late int _limit;

  @override
  void initState() {
    super.initState();
    _limit = widget.limit;
  }

  @override
  Widget build(BuildContext context) {
    final sortedAbsences = List<Map<String, dynamic>>.from(widget.absences)
      ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final isOverLimit = widget.absences.length >= _limit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            MyUzIcons.chevron_left,
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
              style: AppTextStyles.cardDescription(context).copyWith(
                fontSize: 14,
                color: kGreyText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(MyUzIcons.settings,
                color: kGreyText, size: 22),
            tooltip: 'Zmień limit',
            onPressed: _showEditLimitDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Baner z liczbą nieobecności, wyśrodkowany, bez borderów
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: isOverLimit ? kCardRed.withOpacity(0.13) : kCardPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  '${widget.absences.length} / $_limit',
                  style: AppTextStyles.indexAverageValue(context).copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isOverLimit ? kCardRed : kIndexPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  isOverLimit ? 'Przekroczono!' : 'Nieobecności',
                  style: AppTextStyles.cardDescription(context).copyWith(
                    color: isOverLimit ? kCardRed : kIndexPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Lista nieobecności
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 32),
              itemCount: sortedAbsences.length,
              itemBuilder: (context, idx) {
                final absence = sortedAbsences[idx];
                return _buildAbsenceRow(absence, idx);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAbsenceDialog,
        backgroundColor: kIndexPrimary,
        foregroundColor: Colors.white,
        child: Icon(MyUzIcons.plus, size: 24),
        tooltip: 'Dodaj nieobecność',
      ),
    );
  }

  Widget _buildAbsenceRow(Map<String, dynamic> absence, int index) {
    final date = absence['date'] as DateTime? ?? DateTime.now();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showEditAbsenceDialog(absence, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            children: [
              // Kółko z ikoną kalendarza na czerwono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kCardRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    MyUzIcons.calendar_minus,
                    color: kCardRed,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nieobecność',
                  style: AppTextStyles.cardTitle(context).copyWith(
                    fontSize: 15,
                    color: kMainText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DateFormat('dd.MM.yyyy').format(date),
                style: AppTextStyles.cardDescription(context).copyWith(
                  color: kGreyText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLimitDialog() {
    final controller = TextEditingController(text: _limit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Zmień limit nieobecności',
          style: AppTextStyles.cardTitle(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kMainText,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Limit',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anuluj',
                style: AppTextStyles.cardDescription(context)
                    .copyWith(color: kGreyText)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _limit = val;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kIndexPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTextStyles.cardDescription(context).copyWith(
          color: kGreyText,
        ),
      ),
    );
  }

  void _showAddAbsenceDialog() {
    _showAbsenceDialog();
  }

  void _showEditAbsenceDialog(Map<String, dynamic> absence, int index) {
    _showAbsenceDialog(absence: absence, index: index);
  }

  void _showAbsenceDialog({Map<String, dynamic>? absence, int? index}) {
    final isEditing = absence != null;
    final reasonController =
    TextEditingController(text: absence?['reason']?.toString() ?? '');
    DateTime selectedDate = absence?['date'] ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edytuj nieobecność' : 'Dodaj nieobecność',
            style: AppTextStyles.cardTitle(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kMainText,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      helpText: 'Wybierz datę nieobecności',
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
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: kCardBorder.withOpacity(0.3)),
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
                          style: AppTextStyles.cardDescription(context).copyWith(
                            color: kMainText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Powód (opcjonalnie)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kIndexPrimary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Anuluj',
                style: AppTextStyles.cardDescription(context).copyWith(color: kGreyText),
              ),
            ),
            if (isEditing)
              TextButton(
                onPressed: () {
                  widget.onDeleteAbsence(index!);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Text(
                  'Usuń',
                  style: AppTextStyles.cardDescription(context).copyWith(color: kCardRed),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final newAbsence = {
                  'date': selectedDate,
                  'reason': reasonController.text.isNotEmpty ? reasonController.text : null,
                };
                if (isEditing) {
                  widget.onEditAbsence(index!, newAbsence);
                } else {
                  widget.onAddAbsence(newAbsence);
                }
                setState(() {});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kIndexPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEditing ? 'Zapisz' : 'Dodaj',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
