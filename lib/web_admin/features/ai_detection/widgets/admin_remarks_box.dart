import 'package:flutter/material.dart';

const kAiRemarkSuggestions = [
  'Possible AI-generated media. Requires manual verification.',
  'Low confidence result. Needs further review.',
  'Verified as human-made media.',
  'Confirmed AI-generated content.',
  'Please reupload the original photo or video.',
  'Accepted with warning after manual review.',
];

class AdminRemarksBox extends StatelessWidget {
  const AdminRemarksBox({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin remarks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: kAiRemarkSuggestions.map((s) {
            return ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                controller.text = s;
                onChanged?.call(s);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Add admin feedback for the member…'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
