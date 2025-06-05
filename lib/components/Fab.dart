import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../theme/fonts.dart';

// --- Floating Action Button + akcje (Figma: Fab, actions) ---
class Fab extends StatefulWidget {
  final void Function()? onAddZajecia;
  final void Function()? onAddOcena;
  final void Function()? onAddNieobecnosc;
  final void Function()? onAddZadanie;

  const Fab({
    super.key,
    this.onAddZajecia,
    this.onAddOcena,
    this.onAddNieobecnosc,
    this.onAddZadanie,
  });

  @override
  State<Fab> createState() => _FabState();
}

class _FabState extends State<Fab> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _open = false;
      _controller.reverse();
    });
  }

  // --- Fab Action Button (Figma: fab action) ---
  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required void Function()? onTap,
    required int index,
  }) {
    final textStyle = AppTextStyles.cardTitle(context).copyWith(
      color: kMainText,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    );
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(label, style: textStyle),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: label,
              mini: true,
              backgroundColor: kWhite,
              elevation: 2,
              onPressed: () {
                _close();
                onTap?.call();
              },
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Kolory Figma: Fab primary, error ---
    final primary = kNavSelected;
    final error = kError;
    final onPrimary = kWhite;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 76, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAction(
                  icon: Icons.grade,
                  label: 'Ocena',
                  color: primary,
                  onTap: widget.onAddOcena,
                  index: 0,
                ),
                _buildAction(
                  icon: Icons.remove_circle,
                  label: 'Nieobecność',
                  color: error,
                  onTap: widget.onAddNieobecnosc,
                  index: 1,
                ),
                _buildAction(
                  icon: Icons.assignment,
                  label: 'Zadanie',
                  color: primary,
                  onTap: widget.onAddZadanie,
                  index: 2,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            backgroundColor: primary,
            elevation: 8,
            shape: const CircleBorder(),
            onPressed: _toggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _open ? Icons.close : Icons.add,
                key: ValueKey(_open),
                color: onPrimary,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}