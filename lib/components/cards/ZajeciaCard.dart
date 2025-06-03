import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../my_uz_icons.dart';

class ZajeciaCard extends StatelessWidget {
  final String title;
  final String time;
  final String room;
  final String avatarText;
  final Color backgroundColor;

  const ZajeciaCard({
    Key? key,
    required this.title,
    required this.time,
    required this.room,
    required this.avatarText,
    required this.backgroundColor,
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
                    Text(
                      room,
                      style: AppTextStyles.cardDescription(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Avatar po prawej (32x32)
          Container(
            width: 32,
            height: 32,
            decoration: const ShapeDecoration(
              color: Color(0xFF6750A4),
              shape: OvalBorder(),
            ),
            child: Center(
              child: Text(
                avatarText,
                textAlign: TextAlign.center,
                style: AppTextStyles.initialLetter(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
