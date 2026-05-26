import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank == 1) return _trophy(Icons.emoji_events, const Color(0xFFD97706), '1st');
    if (rank == 2) return _trophy(Icons.workspace_premium, const Color(0xFF94A3B8), '2nd');
    if (rank == 3) return _trophy(Icons.military_tech, const Color(0xFFB45309), '3rd');

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _trophy(IconData icon, Color color, String label) {
    return Tooltip(
      message: '$label place',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
