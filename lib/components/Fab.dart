import 'package:flutter/material.dart';

class Fab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _FabButton(
      onAddZajecia: onAddZajecia,
      onAddOcena: onAddOcena,
      onAddNieobecnosc: onAddNieobecnosc,
      onAddZadanie: onAddZadanie,
    );
  }
}

class _FabButton extends StatefulWidget {
  final void Function()? onAddZajecia;
  final void Function()? onAddOcena;
  final void Function()? onAddNieobecnosc;
  final void Function()? onAddZadanie;

  const _FabButton({
    this.onAddZajecia,
    this.onAddOcena,
    this.onAddNieobecnosc,
    this.onAddZadanie,
  });

  @override
  State<_FabButton> createState() => _FabButtonState();
}

class _FabButtonState extends State<_FabButton>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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

  Widget _buildAction(
      {required IconData icon,
        required String label,
        required Color color,
        required void Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: label,
            mini: true,
            backgroundColor: Colors.white,
            elevation: 2,
            onPressed: () {
              _close();
              onTap?.call();
            },
            child: Icon(icon, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF6750A4);
    final Color secondary = const Color(0xFF7D5260);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Actions
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 76, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAction(
                  icon: Icons.event,
                  label: 'Zajęcia',
                  color: primary,
                  onTap: widget.onAddZajecia,
                ),
                _buildAction(
                  icon: Icons.grade,
                  label: 'Ocena',
                  color: primary,
                  onTap: widget.onAddOcena,
                ),
                _buildAction(
                  icon: Icons.remove_circle,
                  label: 'Nieobecność',
                  color: secondary,
                  onTap: widget.onAddNieobecnosc,
                ),
                _buildAction(
                  icon: Icons.assignment,
                  label: 'Zadanie',
                  color: primary,
                  onTap: widget.onAddZadanie,
                ),
              ],
            ),
          ),
        // FAB
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: _toggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _open ? Icons.close : Icons.add,
                key: ValueKey(_open),
                color: primary,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
