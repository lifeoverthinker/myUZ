import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/fonts.dart';
import '../services/supabase_service.dart';
import '../components/profile/user_profile.dart';
import '../components/calendar/calendar_day_view.dart';
import '../utils/debug_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final ScrollController _scrollController = ScrollController();
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  Future<List<Map<String, dynamic>>>
  _fetchZajeciaForSelectedDayAllGroups() async {
    final grupy = userProfile.grupy.value;
    List<Map<String, dynamic>> allZajecia = [];
    for (final group in grupy) {
      final zajecia = await _supabaseService.fetchZajeciaForDay(
        _selectedDay,
        group.kodGrupy,
        group.podgrupa,
      );
      allZajecia.addAll(zajecia);
    }
    allZajecia.sort(
      (a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])),
    );
    return allZajecia;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: ShapeDecoration(
        color: const Color(0xFFE8DEF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1D192B), size: 24),
        onPressed: onTap,
        splashRadius: 24,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  String _monthName(DateTime date) {
    const months = [
      '',
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień',
    ];
    return months[date.month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F9),
      body: SafeArea(
        child: Column(
          children: [
            // Nagłówek kalendarza
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _circleButton(icon: Icons.menu, onTap: () {}),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _calendarFormat =
                            _calendarFormat == CalendarFormat.month
                                ? CalendarFormat.week
                                : CalendarFormat.month;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthName(_focusedDay),
                          style: AppTextStyles.calendarMonthName(context),
                        ),
                        const SizedBox(width: 4),
                        TweenAnimationBuilder(
                          tween: Tween(
                            begin: 0.0,
                            end:
                                _calendarFormat == CalendarFormat.month
                                    ? 0.5
                                    : 0.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 3.1415926535 * 2,
                              child: child,
                            );
                          },
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF6750A4),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _circleButton(icon: Icons.search, onTap: () {}),
                  const SizedBox(width: 6),
                  _circleButton(icon: Icons.add, onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Kalendarz
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                locale: 'pl_PL',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate:
                    (day) =>
                        day.year == _selectedDay.year &&
                        day.month == _selectedDay.month &&
                        day.day == _selectedDay.day,
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
                onFormatChanged: _onFormatChanged,
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF6750A4),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: AppTextStyles.calendarDayNumber(
                    context,
                  ).copyWith(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: AppTextStyles.calendarDayNumber(
                    context,
                  ).copyWith(color: Colors.white),
                  defaultTextStyle: AppTextStyles.calendarDayNumber(
                    context,
                  ).copyWith(color: const Color(0xFF494949)),
                  weekendTextStyle: AppTextStyles.calendarDayNumber(
                    context,
                  ).copyWith(color: const Color(0xFF494949)),
                  outsideTextStyle: AppTextStyles.calendarDayNumber(
                    context,
                  ).copyWith(
                    color: const Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w400,
                  ),
                  cellMargin: const EdgeInsets.all(2),
                  markerDecoration: const BoxDecoration(),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTextStyles.calendarHour(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                    color: const Color(0xFF494949),
                  ),
                  weekendStyle: AppTextStyles.calendarHour(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                    color: const Color(0xFF494949),
                  ),
                  dowTextFormatter: (date, locale) {
                    const dowShorts = ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'];
                    return dowShorts[date.weekday - 1];
                  },
                ),
                headerVisible: false,
              ),
            ),
            const SizedBox(height: 8),
            // Siatka godzinowa z zajęciami
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: userProfile.grupy,
                builder: (context, grupy, _) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchZajeciaForSelectedDayAllGroups(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Błąd: ${snapshot.error}'));
                      }
                      final zajecia = snapshot.data ?? [];
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < 0) {
                              setState(() {
                                _focusedDay = _focusedDay.add(
                                  const Duration(days: 1),
                                );
                                _selectedDay = _focusedDay;
                              });
                            } else if (details.primaryVelocity! > 0) {
                              setState(() {
                                _focusedDay = _focusedDay.subtract(
                                  const Duration(days: 1),
                                );
                                _selectedDay = _focusedDay;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom,
                            left: 16,
                            right: 16,
                          ),
                          child: CalendarDayView(
                            zajecia: zajecia,
                            scrollController: _scrollController,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
