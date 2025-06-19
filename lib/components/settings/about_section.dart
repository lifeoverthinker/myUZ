import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kCardPurple,
              child: const Icon(Icons.info, color: kMainText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O aplikacji',
                    style: AppTextStyles.cardDescription(
                      context,
                    ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wersja 1.0.0',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'myUZ to aplikacja mobilna dla studentów Uniwersytetu Zielonogórskiego, która umożliwia łatwe zarządzanie planem zajęć, ocenami i innymi aspektami studiów.',
          style: TextStyle(color: kMainText, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}
