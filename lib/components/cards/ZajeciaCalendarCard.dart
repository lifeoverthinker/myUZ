import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../my_uz_icons.dart';

class ZajeciaCalendarCard extends StatelessWidget {
  final String title;
  final String time;
  final String room;
  final Color backgroundColor;
  final Color dotColor;

  const ZajeciaCalendarCard({
    Key? key,
    required this.title,
    required this.time,
    required this.room,
    required this.backgroundColor,
    required this.dotColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sekcja tekstowa – elastyczna!
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      MyUZicons.clock,
                      size: 16,
                      color: const Color(0xFF494949),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        time,
                        style: AppTextStyles.cardDescription(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        room,
                        style: AppTextStyles.cardDescription(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Kropka po prawej (8x8)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
