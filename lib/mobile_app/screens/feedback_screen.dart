import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _msgCtrl = TextEditingController();
  String _type = 'Suggestion';
  String? _selectedEvent;
  int _rating = 0;
  bool _sent = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an event'), backgroundColor: kRed));
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please give a star rating'), backgroundColor: kRed));
      return;
    }
    if (_msgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please write your feedback'), backgroundColor: kRed));
      return;
    }
    final requestId = int.tryParse(_selectedEvent!.split('|').first);
    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid event selection'), backgroundColor: kRed));
      return;
    }
    try {
      await memberDataController.submitFeedback(
        requestId: requestId,
        rating: _rating,
        comment: '${_type}: ${_msgCtrl.text.trim()}',
      );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: kRed));
      }
    }
  }

  void _reset() {
    _msgCtrl.clear();
    setState(() {
      _sent = false;
      _selectedEvent = null;
      _rating = 0;
      _type = 'Suggestion';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Feedback', style: TextStyle(color: kTextPrimary,
            fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Rate and review an ACCESS event.',
            style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          if (_sent) ...[
            _SuccessBanner(onNew: _reset),
            const SizedBox(height: 24),
          ] else ...[
            _FeedbackForm(
              msgCtrl: _msgCtrl,
              type: _type,
              selectedEvent: _selectedEvent,
              rating: _rating,
              onTypeChanged: (t) => setState(() => _type = t),
              onEventChanged: (e) => setState(() => _selectedEvent = e),
              onRatingChanged: (r) => setState(() => _rating = r),
              onSubmit: _submit,
            ),
            const SizedBox(height: 24),
          ],

          // Past feedback list
          if (appState.feedbacks.isNotEmpty) ...[
            const Text('Past Feedback', style: TextStyle(color: kTextPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...appState.feedbacks.map((fb) => _FeedbackCard(fb: fb)),
          ],
        ]),
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  final VoidCallback onNew;
  const _SuccessBanner({required this.onNew});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kGreenDim,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kGreen.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.check_circle, color: kGreen, size: 28),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Feedback submitted!', style: TextStyle(color: kGreen,
          fontWeight: FontWeight.w700, fontSize: 14)),
        SizedBox(height: 2),
        Text('Thank you for helping improve ACCESS events.',
          style: TextStyle(color: kGreen, fontSize: 12)),
      ])),
      TextButton(
        onPressed: onNew,
        child: const Text('New', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700))),
    ]),
  );
}

// ── Feedback form ─────────────────────────────────────────────────────────────
class _FeedbackForm extends StatelessWidget {
  final TextEditingController msgCtrl;
  final String type;
  final String? selectedEvent;
  final int rating;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String?> onEventChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _FeedbackForm({
    required this.msgCtrl, required this.type,
    required this.selectedEvent, required this.rating,
    required this.onTypeChanged, required this.onEventChanged,
    required this.onRatingChanged, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final events = appState.challenges
        .where((c) => c.requestId != null)
        .map((c) => '${c.requestId}|${c.title}')
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Event selector
        const Text('Select Event', style: TextStyle(color: kTextSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: kSurfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selectedEvent != null ? kAccent : kBorder)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedEvent,
              isExpanded: true,
              hint: const Text('Choose an event...', style: TextStyle(color: kTextSecondary, fontSize: 13)),
              dropdownColor: kSurface,
              icon: const Icon(Icons.keyboard_arrow_down, color: kTextSecondary),
              items: events.map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e.contains('|') ? e.split('|').last : e,
                  style: const TextStyle(color: kTextPrimary, fontSize: 13),
                ))).toList(),
              onChanged: onEventChanged,
            ),
          ),
        ),

        // Show event tag + date if selected
        if (selectedEvent != null) ...[
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final title = selectedEvent!.contains('|')
                ? selectedEvent!.split('|').last
                : selectedEvent!;
            final ev = appState.events.where((e) => e.title == title).firstOrNull ??
                CalendarEvent(
                  tag: 'TASK',
                  title: title,
                  date: '',
                  status: 'ASSIGNED',
                  statusColor: kAccent,
                  description: '',
                );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: kBlueDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kAccent.withOpacity(0.3))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(ev.tag, style: const TextStyle(color: kAccent,
                    fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                const SizedBox(width: 10),
                Expanded(child: Text(ev.date, style: const TextStyle(
                  color: kTextSecondary, fontSize: 11))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ev.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(ev.status, style: TextStyle(
                    color: ev.statusColor, fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
            );
          }),
        ],

        const SizedBox(height: 20),

        // Star rating
        const Text('Overall Rating', style: TextStyle(color: kTextSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          ...List.generate(5, (i) => GestureDetector(
            onTap: () => onRatingChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < rating ? kYellow : kTextSecondary,
                size: 36)))),
          const SizedBox(width: 8),
          if (rating > 0)
            Text(_ratingLabel(rating), style: TextStyle(
              color: _ratingColor(rating),
              fontSize: 13, fontWeight: FontWeight.w700)),
        ]),

        const SizedBox(height: 20),

        // Feedback type
        const Text('Feedback Type', style: TextStyle(color: kTextSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: ['Suggestion', 'Compliment', 'Concern', 'Other']
          .map((t) => GestureDetector(
            onTap: () => onTypeChanged(t),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: type == t ? kAccent : kSurfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: type == t ? kAccent : kBorder)),
              child: Text(t, style: TextStyle(
                color: type == t ? Colors.white : kTextSecondary,
                fontSize: 12, fontWeight: FontWeight.w600))),
          )).toList()),

        const SizedBox(height: 16),

        // Message
        const Text('Message', style: TextStyle(color: kTextSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: msgCtrl, maxLines: 4,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Share your thoughts about this event...',
            hintStyle: const TextStyle(color: kTextSecondary),
            filled: true, fillColor: kSurfaceAlt,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAccent)))),

        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: onSubmit,
            child: const Text('Submit Feedback',
              style: TextStyle(fontWeight: FontWeight.w700)))),
      ]),
    );
  }

  String _ratingLabel(int r) => switch (r) {
    5 => 'Excellent',
    4 => 'Good',
    3 => 'Average',
    2 => 'Poor',
    _ => 'Very Poor',
  };

  Color _ratingColor(int r) => r >= 4 ? kGreen : r == 3 ? kYellow : kRed;
}

// ── Past feedback card ────────────────────────────────────────────────────────
class _FeedbackCard extends StatelessWidget {
  final EventFeedback fb;
  const _FeedbackCard({required this.fb});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(fb.eventTitle, style: const TextStyle(color: kTextPrimary,
          fontSize: 13, fontWeight: FontWeight.w700))),
        // Stars
        Row(children: List.generate(5, (i) => Icon(
          i < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < fb.rating ? kYellow : kBorder, size: 14))),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Text(fb.type, style: const TextStyle(color: kAccent,
            fontSize: 10, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Text(fb.date, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      ]),
      const SizedBox(height: 8),
      Text(fb.message, style: const TextStyle(color: kTextSecondary,
        fontSize: 12, height: 1.4)),
    ]),
  );
}
