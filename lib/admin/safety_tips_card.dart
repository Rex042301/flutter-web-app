import 'dart:ui';
import 'package:flutter/material.dart';

class SafetyTipsCard extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback? onTap;

  const SafetyTipsCard({super.key, required this.isAdmin, this.onTap});

  @override
  State<SafetyTipsCard> createState() => _SafetyTipsCardState();
}

class _SafetyTipsCardState extends State<SafetyTipsCard> {
  bool _showIcons = false;

  void _toggleIcons() {
    if (widget.isAdmin) setState(() => _showIcons = !_showIcons);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width / 3 * 0.9;

    return GestureDetector(
      onTap: widget.onTap ?? _toggleIcons,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Flexible(
                flex: 3,
                child: Icon(Icons.health_and_safety_rounded, size: height * 0.3, color: Colors.blueAccent),
              ),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    "Safety Tips",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Spacer(),
              if (_showIcons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.orangeAccent), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent), onPressed: () {}),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
