import 'package:flutter/material.dart';
import '../../theme/fonts.dart';

class CalendarHeader extends StatelessWidget {
  final String monthName;
  final bool isMonthFormat;
  final VoidCallback onToggleFormat;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  const CalendarHeader({
    super.key,
    required this.monthName,
    required this.isMonthFormat,
    required this.onToggleFormat,
    required this.onMenu,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _circleButton(icon: Icons.menu, onTap: onMenu),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onToggleFormat,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthName,
                  style: AppTextStyles.calendarMonthName(context),
                ),
                const SizedBox(width: 4),
                TweenAnimationBuilder(
                  tween: Tween(
                    begin: 0.0,
                    end: isMonthFormat ? 0.5 : 0.0,
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
          _circleButton(icon: Icons.search, onTap: onSearch),
          const SizedBox(width: 6),
          _circleButton(icon: Icons.add, onTap: onAdd),
        ],
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
        icon: Icon(icon, color: const Color(0xFF6750A4), size: 24),
        onPressed: onTap,
        splashRadius: 24,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}