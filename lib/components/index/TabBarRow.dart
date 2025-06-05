import 'package:flutter/material.dart';
import '../../theme/theme.dart';

// --- TabBarRow (Figma: TabBar, różne sekcje Index) ---
class TabBarRow extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final void Function(int idx) onTabChanged;

  const TabBarRow({
    Key? key,
    required this.selectedIndex,
    required this.labels,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (idx) {
        final isSelected = selectedIndex == idx;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < labels.length - 1 ? 4 : 0),
            child: GestureDetector(
              onTap: () => onTabChanged(idx),
              child: Container(
                height: 32,
                decoration: ShapeDecoration(
                  color: isSelected ? kCardPurple : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isSelected
                        ? BorderSide.none
                        : const BorderSide(
                      width: 1,
                      color: kCardBorder,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? kMainText : kGreyText,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                      letterSpacing: 0.10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}