import 'package:flutter/material.dart';
import '../theme/fonts.dart';

class WydarzeniaCard extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;

  const WydarzeniaCard({
    super.key,
    required this.title,
    required this.description,
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 239,
                  child: Text(title, style: AppTextStyles.bodyMedium(context)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 239,
                  child: Text(description, style: AppTextStyles.labelLarge(context)),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const ShapeDecoration(
              color: Color(0xFF7D5260),
              shape: OvalBorder(),
            ),
          ),
        ],
      ),
    );
  }
}