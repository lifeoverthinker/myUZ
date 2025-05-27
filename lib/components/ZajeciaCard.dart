import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/fonts.dart';

class ZajeciaCard extends StatelessWidget {
  final String title;
  final String time;
  final String room;
  final String avatarText;
  final Color backgroundColor;

  const ZajeciaCard({
    super.key,
    required this.title,
    required this.time,
    required this.room,
    required this.avatarText,
    required this.backgroundColor,
  });

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 215,
                  child: Text(
                    title,
                    style: AppTextStyles.classTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/clock.svg',
                      height: 16,
                      width: 16,
                      color: const Color(0xFF1D192B),
                    ),
                    const SizedBox(width: 4),
                    Text(time, style: AppTextStyles.classInfoText(context)),
                    const SizedBox(width: 16),
                    Text(room, style: AppTextStyles.classInfoText(context)),
                  ],
                ),
              ],
            ),
          ),
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
                style: AppTextStyles.classTypeInitial(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
