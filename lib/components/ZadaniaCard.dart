import 'package:flutter/material.dart';
import '../theme/fonts.dart';

class ZadaniaCard extends StatelessWidget {
  final String title;
  final String description;
  final String avatarText;
  final Color backgroundColor;

  const ZadaniaCard({
    super.key,
    required this.title,
    required this.description,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 8),
                Text(description, style: AppTextStyles.labelLarge(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: const ShapeDecoration(
              color: Color(0xFF7D5260),
              shape: OvalBorder(),
            ),
            child: Center(
              child: Text(
                avatarText,
                textAlign: TextAlign.center,
                style: AppTextStyles.classTypeInitial(
                  context,
                ).copyWith(color: const Color(0xFFFFFBFE)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
