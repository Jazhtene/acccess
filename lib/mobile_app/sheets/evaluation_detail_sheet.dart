import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/mobile_app/widgets/score_ring.dart';

class DetailMetric extends StatelessWidget {
  final String label, value;
  const DetailMetric({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kSurfaceAlt,
      borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
        style: const TextStyle(color: kTextSecondary, fontSize: 9, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
  );
}

void showEvaluationDetail(BuildContext context, Evaluation ev) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(ev.title, style: const TextStyle(color: kTextPrimary,
              fontSize: 18, fontWeight: FontWeight.w800))),
            Text(ev.id, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(ev.date, style: const TextStyle(color: kTextSecondary, fontSize: 12)),

          if (ev.imageUrl != null && ev.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(ev.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          // Photos displayed prominently at the top
          if (ev.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ev.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _showFullImage(context, ev.images[i]),
                  child: Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(ev.images[i],
                        width: 160, height: 160, fit: BoxFit.cover)),
                    // Score badge on first photo
                    if (i == 0 && ev.score > 0)
                      Positioned(bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('${(ev.score * 100).round()}%',
                            style: const TextStyle(color: Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w800)))),
                    // Tap to expand hint
                    Positioned(top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 14))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('${ev.images.length} photo(s) · tap to view full size',
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],

          const SizedBox(height: 20),
          Center(child: ScoreRing(score: ev.score, label: ev.score == 0.0 ? '—' : '${(ev.score * 100).round()}%')),
          const SizedBox(height: 24),
          const Divider(color: kBorder),
          const SizedBox(height: 16),
          const Text('METRICS', style: TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DetailMetric(label: 'Composition', value: ev.composition)),
            const SizedBox(width: 12),
            Expanded(child: DetailMetric(label: 'Lighting', value: ev.lighting)),
          ]),
          const SizedBox(height: 16),
          const Text('FEEDBACK', style: TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kSurfaceAlt,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Text('"${ev.feedback}"', style: const TextStyle(color: kTextPrimary,
              fontSize: 13, fontStyle: FontStyle.italic, height: 1.5))),

          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kCyan, foregroundColor: kBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    ),
  );
}

void showReportDialog(BuildContext context, Evaluation ev) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Report Assessment', style: TextStyle(color: kTextPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Report an issue with ${ev.id}?',
          style: const TextStyle(color: kTextSecondary)),
        const SizedBox(height: 16),
        TextField(maxLines: 3, style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
            hintStyle: TextStyle(color: kTextSecondary))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: kBg),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Report submitted'), backgroundColor: kGreen));
          },
          child: const Text('Submit')),
      ],
    ),
  );
}

void _showFullImage(BuildContext context, Uint8List bytes) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
    ),
  ));
}
