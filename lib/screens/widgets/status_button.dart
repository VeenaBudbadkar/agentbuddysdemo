import 'package:flutter/material.dart';

class StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final double textSize;

  const StatusButton({super.key, required this.label, required this.color, this.textSize = 14});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () {},
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: textSize)),
    );
  }
}
