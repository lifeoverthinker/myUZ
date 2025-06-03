import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../cards/ZajeciaCalendarCard.dart';

class CalendarDayView extends StatelessWidget {
  static const int startHour = 1;
  static const int endHour = 23;
  static const double hourRowHeight = 70;
  static const double hourLabelWidth = 48;
  static const double verticalLineOffset = 8;
  static const double verticalLineWidth = 1;
  static const double horizontalLineHeight = 1;
  static const Color lineColor = Color(0xFFEDE6F3);

  final List<Map<String, dynamic>> zajecia;

  const CalendarDayView({super.key, required this.zajecia});

  @override
  Widget build(BuildContext context) {
    final hourCount = endHour - startHour + 1;
    final totalHeight = hourCount * hourRowHeight;

    // Sortowanie zajęć po czasie rozpoczęcia
    final zajeciaSorted = List<Map<String, dynamic>>.from(zajecia)
      ..sort((a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])));

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Warstwa godzinowa (tło)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hourCount,
              itemBuilder: (context, index) {
                final hour = startHour + index;
                return SizedBox(
                  height: hourRowHeight,
                  child: Stack(
                    children: [
                      // Pozioma linia na środku godziny
                      Positioned(
                        left: hourLabelWidth + verticalLineOffset,
                        right: 0,
                        top: hourRowHeight / 2,
                        child: Container(
                          height: horizontalLineHeight,
                          color: lineColor,
                        ),
                      ),
                      // Godzina po lewej
                      Positioned(
                        left: 0,
                        top: 0,
                        width: hourLabelWidth,
                        height: hourRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: AppTextStyles.calendarHour(context).copyWith(
                              color: const Color(0xFF616161),
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
              left: hourLabelWidth + 16,
              top: 0,
              bottom: 0,
              child: Container(width: verticalLineWidth, color: lineColor),
            ),
            // Karty zajęć precyzyjnie przyczepione do godzin/minut
            ...zajeciaSorted.map((zajecie) {
              final start = DateTime.parse(zajecie['od']);
              final end = DateTime.parse(zajecie['do_']);
              final hourOffset = (start.hour - startHour) * hourRowHeight +
                  (start.minute / 60.0) * hourRowHeight;
              final durationMinutes = end.difference(start).inMinutes;
              final cardHeight = (durationMinutes / 60.0) * hourRowHeight;

              return Positioned(
                left: hourLabelWidth + 24,
                top: hourOffset,
                width: 264,
                height: cardHeight,
                child: ZajeciaCalendarCard(
                  title: zajecie['przedmiot'] ?? '',
                  time: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  room: zajecie['miejsce'] ?? '',
                  backgroundColor: const Color(0xFFE8DEF8),
                  dotColor: const Color(0xFF6750A4),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
