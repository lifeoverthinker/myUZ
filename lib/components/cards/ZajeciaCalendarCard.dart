import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../../my_uz_icons.dart';

class ZajeciaCalendarCard extends StatelessWidget {
  final String title;
  final String time;
  final String room;
  final Color backgroundColor;
  final Color dotColor;
  final VoidCallback? onTap;

  const ZajeciaCalendarCard({
    super.key,
    required this.title,
    required this.time,
    required this.room,
    required this.backgroundColor,
    required this.dotColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 264,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: backgroundColor, // pastelowy, NIEprzezroczysty!
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.cardTitle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(MyUzIcons.clock, size: 16, color: kGreyText),
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
            ],
          ),
        ),
      ),
    );
  }
}
