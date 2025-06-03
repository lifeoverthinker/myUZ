import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/gestures.dart';
import '../theme/fonts.dart';
import '../components/cards/ZajeciaCalendarCard.dart';
import '../services/supabase_service.dart';

// Mapowanie rodzajów zajęć na kolory kart i kropek
const Map<String, Color> zajeciaColors = {
  'W': Color(0xFFE8DEF8), // wykład
  'C': Color(0xFFD1E7DD), // ćwiczenia
  'L': Color(0xFFFFF3CD), // laboratorium
  'P': Color(0xFFFFD8E4), // projekt
  'S': Color(0xFFD0BCFF), // seminarium
  'default': Color(0xFFE0E0E0),
};

const Map<String, Color> zajeciaDotColors = {
  'W': Color(0xFF6750A4),
  'C': Color(0xFF006E2C),
  'L': Color(0xFFFF8A00),
  'P': Color(0xFFB3261E),
  'S': Color(0xFF381E72),
  'default': Color(0xFF616161),
};

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> zajeciaFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    zajeciaFuture = _fetchZajeciaForSelectedDay();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchZajeciaForSelectedDay() async {
    return _supabaseService.fetchZajeciaForDay(_selectedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      zajeciaFuture = _fetchZajeciaForSelectedDay();
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
                            end: _calendarFormat == CalendarFormat.month ? 0.5 : 0.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 3.1415926535 * 2,
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF6750A4),
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

            // Kalendarz tygodniowy/miesięczny
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                locale: 'pl_PL',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) =>
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
                  selectedTextStyle: AppTextStyles.calendarDayNumber(context).copyWith(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: AppTextStyles.calendarDayNumber(context).copyWith(color: Colors.white),
                  defaultTextStyle: AppTextStyles.calendarDayNumber(context).copyWith(color: const Color(0xFF494949)),
                  weekendTextStyle: AppTextStyles.calendarDayNumber(context).copyWith(color: const Color(0xFF494949)),
                  outsideTextStyle: AppTextStyles.calendarDayNumber(context).copyWith(
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

            // Sekcja godzin + karty zajęć (przewijalna całość)
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      // Swipe w lewo - następny dzień
                      setState(() {
                        _focusedDay = _focusedDay.add(const Duration(days: 1));
                        _selectedDay = _focusedDay;
                        zajeciaFuture = _fetchZajeciaForSelectedDay();
                      });
                    } else if (details.primaryVelocity! > 0) {
                      // Swipe w prawo - poprzedni dzień
                      setState(() {
                        _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                        _selectedDay = _focusedDay;
                        zajeciaFuture = _fetchZajeciaForSelectedDay();
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: zajeciaFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Błąd: ${snapshot.error}'));
                      }
                      final zajecia = snapshot.data ?? [];
                      return CalendarDayView(
                        zajecia: zajecia,
                        scrollController: _scrollController,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}

// --- CalendarDayView widget z automatycznym przewijaniem do pierwszych zajęć i kolorami ---
class CalendarDayView extends StatefulWidget {
  static const int startHour = 1;
  static const int endHour = 23;
  static const double hourRowHeight = 70;
  static const double hourLabelWidth = 48;
  static const double verticalLineOffset = 8;
  static const double verticalLineWidth = 1;
  static const double horizontalLineHeight = 1;
  static const Color lineColor = Color(0xFFEDE6F3);

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
  bool _scrolled = false;

  @override
  void didUpdateWidget(covariant CalendarDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrolled = false;
    _tryScrollToFirstClass();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryScrollToFirstClass();
  }

  void _tryScrollToFirstClass() {
    if (_scrolled || widget.zajecia.isEmpty) return;

    // Znajdź pierwsze zajęcia
    final zajeciaSorted = List<Map<String, dynamic>>.from(widget.zajecia)
      ..sort((a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])));
    final first = zajeciaSorted.first;
    final start = DateTime.parse(first['od']);

    // Oblicz offset scrolla
    final offset = ((start.hour - CalendarDayView.startHour) * CalendarDayView.hourRowHeight) +
        (start.minute / 60.0) * CalendarDayView.hourRowHeight - 16;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          offset.clamp(0, widget.scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
    _scrolled = true;
  }

  @override
  Widget build(BuildContext context) {
    final hourCount = CalendarDayView.endHour - CalendarDayView.startHour + 1;
    final totalHeight = hourCount * CalendarDayView.hourRowHeight;

    final zajeciaSorted = List<Map<String, dynamic>>.from(widget.zajecia)
      ..sort((a, b) => DateTime.parse(a['od']).compareTo(DateTime.parse(b['od'])));

    return SingleChildScrollView(
      controller: widget.scrollController,
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
                final hour = CalendarDayView.startHour + index;
                return SizedBox(
                  height: CalendarDayView.hourRowHeight,
                  child: Stack(
                    children: [
                      // Pozioma linia na środku godziny
                      Positioned(
                        left: CalendarDayView.hourLabelWidth + CalendarDayView.verticalLineOffset,
                        right: 0,
                        top: CalendarDayView.hourRowHeight / 2,
                        child: Container(
                          height: CalendarDayView.horizontalLineHeight,
                          color: CalendarDayView.lineColor,
                        ),
                      ),
                      // Godzina po lewej
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
              left: CalendarDayView.hourLabelWidth + 16,
              top: 0,
              bottom: 0,
              child: Container(
                  width: CalendarDayView.verticalLineWidth,
                  color: CalendarDayView.lineColor),
            ),
            // Karty zajęć precyzyjnie przyczepione do godzin/minut i z odpowiednim kolorem
            ...zajeciaSorted.map((zajecie) {
              final start = DateTime.parse(zajecie['od']);
              final end = DateTime.parse(zajecie['do_']);
              final hourOffset = (start.hour - CalendarDayView.startHour) * CalendarDayView.hourRowHeight +
                  (start.minute / 60.0) * CalendarDayView.hourRowHeight;
              final durationMinutes = end.difference(start).inMinutes;
              final cardHeight = (durationMinutes / 60.0) * CalendarDayView.hourRowHeight;

              final rz = (zajecie['rz'] ?? '').toString().toUpperCase();
              final cardColor = zajeciaColors[rz] ?? zajeciaColors['default']!;
              final dotColor = zajeciaDotColors[rz] ?? zajeciaDotColors['default']!;

              return Positioned(
                left: CalendarDayView.hourLabelWidth + 24,
                top: hourOffset,
                width: 264,
                height: cardHeight,
                child: ZajeciaCalendarCard(
                  title: zajecie['przedmiot'] ?? '',
                  time: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  room: zajecie['miejsce'] ?? '',
                  backgroundColor: cardColor,
                  dotColor: dotColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
