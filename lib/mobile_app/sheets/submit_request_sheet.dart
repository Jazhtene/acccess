import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';

void showSubmitRequest(BuildContext context) {
  final detailsCtrl = TextEditingController();
  String selectedType = 'Membership';
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Submit Request', style: TextStyle(color: kTextPrimary,
            fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Membership & resource requests',
            style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          const Text('Request Type', style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8,
            children: ['Membership', 'Certificate', 'Resource', 'Event', 'Other']
              .map((t) => GestureDetector(
                onTap: () => setModalState(() => selectedType = t),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedType == t ? kCyan : kSurfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedType == t ? kCyan : kBorder)),
                  child: Text(t, style: TextStyle(
                    color: selectedType == t ? kBg : kTextSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600))),
              )).toList()),
          const SizedBox(height: 12),
          TextField(controller: detailsCtrl, maxLines: 3,
            style: const TextStyle(color: kTextPrimary),
            decoration: const InputDecoration(
              labelText: 'Details',
              hintText: 'Describe your request...',
              hintStyle: TextStyle(color: kTextSecondary))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: kBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final details = detailsCtrl.text.trim().isEmpty
                  ? 'No details provided' : detailsCtrl.text.trim();
                appState.submitRequest(selectedType, details);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Request submitted successfully'), backgroundColor: kGreen));
              },
              child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    ),
  );
}
