import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';

class WydarzeniaCard extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;

  const WydarzeniaCard({
    Key? key,
    required this.title,
    required this.description,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tytuł wydarzenia
          SizedBox(
            width: 192,
            child: Text(
              title,
              style: AppTextStyles.cardTitle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Opis wydarzenia
          SizedBox(
            width: 192,
            child: Text(
              description,
              style: AppTextStyles.cardDescription(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}