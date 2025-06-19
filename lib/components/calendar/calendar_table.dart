import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/fonts.dart';

class CalendarTable extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final ValueChanged<DateTime> onPageChanged;

  const CalendarTable({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TableCalendar(
        locale: 'pl_PL',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 52,
        selectedDayPredicate:
            (day) =>
                day.year == selectedDay.year &&
                day.month == selectedDay.month &&
                day.day == selectedDay.day,
        onDaySelected: (selectedDay, focusedDay) {
          onDaySelected(selectedDay);
        },
        onPageChanged: onPageChanged,
        onFormatChanged: onFormatChanged,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTextStyles.calendarHour(context).copyWith(
            color: const Color(0xFF494949),
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.33,
          ),
          weekendStyle: AppTextStyles.calendarHour(context).copyWith(
            color: const Color(0xFF494949),
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.33,
          ),
          dowTextFormatter: (date, locale) {
            const dowShorts = ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'];
            return dowShorts[date.weekday - 1];
          },
          decoration: const BoxDecoration(),
        ),
        headerVisible: false,
        calendarStyle: const CalendarStyle(
          cellMargin: EdgeInsets.zero,
          markerDecoration: BoxDecoration(),
          // Wyłącz domyślne dekoracje
          selectedDecoration: BoxDecoration(),
          todayDecoration: BoxDecoration(),
          defaultDecoration: BoxDecoration(),
          weekendDecoration: BoxDecoration(),
          outsideDecoration: BoxDecoration(),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            // Padding 16 z prawej, rozłożenie do linii pionowej
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  const ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'][day.weekday - 1],
                  style: AppTextStyles.calendarHour(context).copyWith(
                    color: const Color(0xFF494949),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final isSelected =
                day.year == selectedDay.year &&
                day.month == selectedDay.month &&
                day.day == selectedDay.day;
            return Center(
              child:
                  isSelected
                      ? Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6750A4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: AppTextStyles.calendarDayNumber(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      )
                      : Text(
                        '${day.day}',
                        style: AppTextStyles.calendarDayNumber(
                          context,
                        ).copyWith(color: const Color(0xFF494949)),
                      ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4), // Figma: selected day circle
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: AppTextStyles.calendarDayNumber(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final isSelected =
                day.year == selectedDay.year &&
                day.month == selectedDay.month &&
                day.day == selectedDay.day;
            return Center(
              child:
                  isSelected
                      ? Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6750A4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: AppTextStyles.calendarDayNumber(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      )
                      : Text(
                        '${day.day}',
                        style: AppTextStyles.calendarDayNumber(
                          context,
                        ).copyWith(
                          color: const Color(0xFF6750A4),
                        ), // Figma: today text
                      ),
            );
          },

          outsideBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: AppTextStyles.calendarDayNumber(context).copyWith(
                  color: const Color(0xFFB0B0B0),
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
