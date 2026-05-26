import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';

/// Red "AI Detected" badge shown on gallery tiles flagged as AI-generated.
class AiDetectedBadge extends StatelessWidget {
  const AiDetectedBadge({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 8, left: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
          blurRadius: 4, offset: const Offset(0, 1))]),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.smart_toy_outlined, color: Colors.white, size: 11),
        SizedBox(width: 4),
        Text('AI Detected', style: TextStyle(color: Colors.white,
          fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}
