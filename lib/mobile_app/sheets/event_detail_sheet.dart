import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/mobile_app/widgets/shared_widgets.dart';

class OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const OptionTile({super.key, required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    onTap: onTap,
  );
}

void showEventDetail(BuildContext context, CalendarEvent event) {
  showModalBottomSheet(
    context: context, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: kSurfaceAlt,
            borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorder)),
          child: Text(event.tag,
            style: const TextStyle(color: kTextSecondary, fontSize: 10, letterSpacing: 0.8))),
        const SizedBox(height: 10),
        Text(event.title, style: const TextStyle(color: kTextPrimary,
          fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_today_outlined, color: kTextSecondary, size: 14),
          const SizedBox(width: 6),
          Text(event.date, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        StatusDot(color: event.statusColor, label: event.status),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kSurfaceAlt,
            borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
          child: Text(event.description,
            style: const TextStyle(color: kTextPrimary, fontSize: 13, height: 1.5))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: kTextSecondary,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: kBg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${event.title} confirmed'), backgroundColor: kGreen));
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

void showEventOptions(BuildContext context, CalendarEvent event) {
  final idx = appState.events.indexOf(event);
  showModalBottomSheet(
    context: context, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        OptionTile(icon: Icons.check_circle_outline, label: 'Mark Confirmed', color: kGreen,
          onTap: () { appState.updateEventStatus(idx, 'CONFIRMED'); Navigator.pop(context); }),
        OptionTile(icon: Icons.sync, label: 'Sync Now', color: kCyan,
          onTap: () { appState.updateEventStatus(idx, 'SYNCED'); Navigator.pop(context); }),
        OptionTile(icon: Icons.cancel_outlined, label: 'Cancel Event', color: kRed,
          onTap: () { appState.updateEventStatus(idx, 'CANCELLED'); Navigator.pop(context); }),
      ]),
    ),
  );
}

void showFullCalendar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Opening full schedule...'), backgroundColor: kCyan));
}
