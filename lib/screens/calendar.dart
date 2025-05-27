import 'package:flutter/material.dart';
import '../theme/fonts.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<int> days = [15, 16, 17, 18, 19];
  int selectedDay = 16;
  String monthName = "Lipiec";
  int year = 2025;

  List<_Event> getEventsForDay(int day) {
    if (day == 16) {
      return [
        _Event(
          title: 'Podstawy systemów dyskretnych',
          room: 'Sala 102',
          start: const TimeOfDay(hour: 8, minute: 0),
          end: const TimeOfDay(hour: 8, minute: 45),
          color: const Color(0xFFE8DEF8),
          dotColor: const Color(0xFF6750A4),
        ),
        _Event(
          title: 'Lorem ipsum dolor amet',
          room: 'Sala 102',
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 9, minute: 45),
          color: const Color(0xFFFFD8E4),
          dotColor: const Color(0xFF7D5260),
        ),
        _Event(
          title: 'Podstawy systemów dyskretnych',
          room: 'Sala 102',
          start: const TimeOfDay(hour: 10, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 45),
          color: const Color(0xFFE8DEF8),
          dotColor: const Color(0xFF6750A4),
        ),
      ];
    }
    return [];
  }

  final int minHour = 7;
  final int maxHour = 14;

  @override
  Widget build(BuildContext context) {
    final events = getEventsForDay(selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F9),
      body: Column(
        children: [
          // Górny pasek z ikonami i miesiącem
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ikona menu
                Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF7F2F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF6750A4), size: 24),
                    onPressed: () {},
                  ),
                ),
                // Nazwa miesiąca
                Row(
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        color: Color(0xFF1D192B),
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: Color(0xFF6750A4)),
                  ],
                ),
                // Ikony search i plus
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF7F2F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFF6750A4), size: 24),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF7F2F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF6750A4), size: 24),
                        onPressed: () {
                          // Otwórz modal dodawania eventu
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pasek dni tygodnia
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 64, right: 16, top: 8, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ['P', 'W', 'Ś', 'C', 'P']
                  .map((day) => SizedBox(
                width: 24,
                height: 24,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF494949),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          // Pasek dat (wybór dnia)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 64, right: 16, top: 0, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: days.map((date) {
                final bool isSelected = date == selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDay = date;
                    });
                  },
                  child: Container(
                    width: isSelected ? 28 : 24,
                    height: isSelected ? 28 : 24,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6750A4) : Colors.white,
                      borderRadius: BorderRadius.circular(isSelected ? 100 : 12),
                    ),
                    child: Center(
                      child: Text(
                        '$date',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF494949),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Widok dnia z godzinami i eventami (przewijany)
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                height: ((maxHour - minHour + 1) * 71).toDouble(),
                child: Stack(
                  children: [
                    // Godziny po lewej
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          maxHour - minHour + 1,
                              (i) => SizedBox(
                            height: 71,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${(minHour + i).toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                    color: Color(0xFF494949),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Linie siatki
                    ...List.generate(
                      maxHour - minHour + 1,
                          (i) => Positioned(
                        left: 40,
                        top: (i * 71),
                        child: Container(
                          width: 288,
                          height: 1,
                          color: const Color(0xFFEDE6F3),
                        ),
                      ),
                    ),
                    // Karty eventów
                    ...events.map((event) {
                      final double startMinutes = (event.start.hour * 60 + event.start.minute) - (minHour * 60);
                      final double endMinutes = (event.end.hour * 60 + event.end.minute) - (minHour * 60);
                      final double top = (startMinutes / 60) * 71;
                      final double height = ((endMinutes - startMinutes) / 60) * 71;
                      return Positioned(
                        left: 49,
                        top: top,
                        child: _EventCard(event: event, height: height > 40 ? height : 40),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _Event event;
  final double height;
  const _EventCard({required this.event, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 271,
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: event.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 223,
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF494949)),
                    const SizedBox(width: 4),
                    Text(
                      '${event.start.format(context)} - ${event.end.format(context)}',
                      style: const TextStyle(
                        color: Color(0xFF494949),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      event.room,
                      style: const TextStyle(
                        color: Color(0xFF494949),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8, top: 4),
            decoration: BoxDecoration(
              color: event.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Event {
  final String title;
  final String room;
  final TimeOfDay start;
  final TimeOfDay end;
  final Color color;
  final Color dotColor;

  _Event({
    required this.title,
    required this.room,
    required this.start,
    required this.end,
    required this.color,
    required this.dotColor,
  });
}
