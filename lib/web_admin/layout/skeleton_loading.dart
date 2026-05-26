import 'package:flutter/material.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

/// Shimmer-style skeleton placeholders for admin pages.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF1F5F9), _controller.value),
          ),
        );
      },
    );
  }
}

/// Full-page skeleton: header + summary cards + table rows.
class AdminPageSkeleton extends StatelessWidget {
  const AdminPageSkeleton({super.key, this.summaryCount = 4, this.tableRows = 6});

  final int summaryCount;
  final int tableRows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 280, height: 28, radius: 6),
          const SizedBox(height: 10),
          const SkeletonBox(width: 420, height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(width: 320, height: 12),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cross = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cross,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.4,
                children: List.generate(summaryCount, (_) => _summarySkeleton()),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AdminTheme.cardDecoration(),
            child: const SkeletonBox(width: double.infinity, height: 40),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AdminTheme.cardDecoration(),
            child: Column(
              children: [
                const SkeletonBox(width: double.infinity, height: 36),
                const SizedBox(height: 12),
                ...List.generate(tableRows, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: const SkeletonBox(width: double.infinity, height: 44),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySkeleton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminTheme.cardDecoration(),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 80, height: 22),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 160, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
