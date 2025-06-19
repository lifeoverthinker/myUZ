import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../cards/ZajeciaCalendarCard.dart';
import '../cards/zajecia_details_modal.dart';
import '../profile/user_profile.dart';

class CalendarDayView extends StatefulWidget {
  static const int startHour = 1;
  static const int endHour = 23;
  static const double hourRowHeight = 70;
  static const double hourLabelWidth = 48;
  static const double verticalLineOffset = 8;
  static const double verticalLineWidth = 1;
  static const double horizontalLineHeight = 1;

  final List<Map<String, dynamic>> zajecia;
  final ScrollController scrollController;

  const CalendarDayView({
    super.key,
    required this.zajecia,
    required this.scrollController,
  });

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  bool _hasScrolledToFirstClass = false;

  @override
  void didUpdateWidget(covariant CalendarDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasScrolledToFirstClass = false;
    _scrollToFirstClass();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollToFirstClass();
  }

  void _scrollToFirstClass() {
    if (_hasScrolledToFirstClass || widget.zajecia.isEmpty) return;
    final zajeciaSorted = List<Map<String, dynamic>>.from(widget.zajecia)..sort(
      (a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])),
    );
    if (zajeciaSorted.isNotEmpty) {
      final now = DateTime.now();
      final firstFutureClass = zajeciaSorted.firstWhere(
        (z) => DateTime.parse(z['od']).isAfter(now),
        orElse: () => zajeciaSorted.first,
      );
      final start = DateTime.parse(firstFutureClass['od']);
      final offset =
          ((start.hour - CalendarDayView.startHour) *
                  CalendarDayView.hourRowHeight +
              (start.minute / 60.0) * CalendarDayView.hourRowHeight) -
          16;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients && !_hasScrolledToFirstClass) {
          widget.scrollController.animateTo(
            offset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
          _hasScrolledToFirstClass = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hourCount = CalendarDayView.endHour - CalendarDayView.startHour + 1;
    final totalHeight = hourCount * CalendarDayView.hourRowHeight;
    final zajeciaSorted = List<Map<String, dynamic>>.from(widget.zajecia)..sort(
      (a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])),
    );

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Warstwa godzinowa
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hourCount,
              itemBuilder: (context, index) {
                final hour = CalendarDayView.startHour + index;
                return SizedBox(
                  height: CalendarDayView.hourRowHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left:
                            CalendarDayView.hourLabelWidth +
                            CalendarDayView.verticalLineOffset,
                        right: 0,
                        top: CalendarDayView.hourRowHeight / 2,
                        child: Container(
                          height: CalendarDayView.horizontalLineHeight,
                          color: const Color(
                            0xFFEDE6F3,
                          ), // Figma: calendar line (linia godziny)
                        ),
                      ),

                      Positioned(
                        left: 0,
                        top: 0,
                        width: CalendarDayView.hourLabelWidth,
                        height: CalendarDayView.hourRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: AppTextStyles.calendarHour(context).copyWith(
                              color: kGreyText,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Pionowa linia
            Positioned(
              left: CalendarDayView.hourLabelWidth + 16,
              top: 0,
              bottom: 0,
              child: Container(
                width: CalendarDayView.verticalLineWidth,
                color: kCalendarLine,
              ),
            ),
            // Karty zajęć
            ...zajeciaSorted.map((zajecie) {
              final start = DateTime.parse(zajecie['od']);
              final end = DateTime.parse(zajecie['do_']);
              final hourOffset =
                  (start.hour - CalendarDayView.startHour) *
                      CalendarDayView.hourRowHeight +
                  (start.minute / 60.0) * CalendarDayView.hourRowHeight;
              final durationMinutes = end.difference(start).inMinutes;
              final cardHeight =
                  (durationMinutes / 60.0) * CalendarDayView.hourRowHeight;

              final rz = zajecie['rz']?.toString().toUpperCase() ?? '';
              final mainColor = userProfile.getColorForSubjectType(rz);

              return Positioned(
                left: CalendarDayView.hourLabelWidth + 24,
                top: hourOffset,
                width: 264,
                height: cardHeight,
                child: ZajeciaCalendarCard(
                  title: zajecie['przedmiot'] ?? '',
                  time:
                      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  room: zajecie['miejsce'] ?? '',
                  backgroundColor: mainColor,
                  dotColor: mainColor,
                  onTap:
                      () => showZajeciaDetailsModal(
                        context,
                        zajecie,
                        backgroundColor: mainColor,
                        dotColor: mainColor,
                      ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
