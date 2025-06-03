import 'package:flutter/material.dart';
import '../../theme/fonts.dart';

class ZadaniaCard extends StatelessWidget {
  final String title;
  final String description;
  final String avatarText;
  final Color backgroundColor;

  const ZadaniaCard({
    Key? key,
    required this.title,
    required this.description,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dane zadania
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tytuł zadania
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
                // Opis zadania
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
          ),
          const SizedBox(width: 16),
          // Avatar z inicjałem
          Container(
            width: 32,
            height: 32,
            decoration: const ShapeDecoration(
              color: Color(0xFF7D5260), // Figma: avatar zadania
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
