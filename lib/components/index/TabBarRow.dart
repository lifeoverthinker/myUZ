import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../../my_uz_icons.dart';

// TabBarRow: prostokątne, zaokrąglone zakładki na gridzie 8, bez wspólnej otoczki (Figma: Tab switcher)
class TabBarRow extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final void Function(int idx) onTabChanged;

  const TabBarRow({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      MyUzIcons.graduation_hat,
      MyUzIcons.calendar_minus_02_svgrepo_com,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(labels.length, (idx) {
        final isSelected = selectedIndex == idx;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: idx == 0 ? 0 : 8,
              right: idx == labels.length - 1 ? 0 : 0,
            ),
            child: GestureDetector(
              onTap: () => onTabChanged(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12), // Zmniejszone z 14 na 12 (8*1.5)
                decoration: BoxDecoration(
                  color: isSelected
                      ? kIndexPrimary
                      : kCardPurple.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(12), // grid 8*1.5
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: kIndexPrimary.withOpacity(0.16), // Zmniejszone z 0.2
                      blurRadius: 8, // Zmniejszone z 12 (8*1)
                      offset: const Offset(0, 2), // Zmniejszone z 3 (8*0.25)
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[idx],
                      size: 16, // Zmniejszone z 20 na 16 (8*2)
                      color: isSelected ? Colors.white : kIndexPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      labels[idx],
                      style: AppTextStyles.indexCategoryTitle(context).copyWith(
                        color: isSelected ? Colors.white : kIndexPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14, // Zmniejszone z 16 na 14
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
