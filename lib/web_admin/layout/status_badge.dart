import 'package:flutter/material.dart';

import 'package:access_mobile/web_admin/theme/admin_theme.dart';



/// Generic colored status pill for tables and lists.

class StatusBadge extends StatelessWidget {

  const StatusBadge({

    super.key,

    required this.label,

    required this.color,

  });



  final String label;

  final Color color;



  factory StatusBadge.approved([String label = 'Approved']) =>

      StatusBadge(label: label, color: AdminTheme.success);



  factory StatusBadge.pending([String label = 'Pending']) =>

      StatusBadge(label: label, color: AdminTheme.warning);



  factory StatusBadge.rejected([String label = 'Rejected']) =>

      StatusBadge(label: label, color: AdminTheme.danger);



  factory StatusBadge.human([String label = 'Human']) =>

      StatusBadge(label: label, color: AdminTheme.success);



  factory StatusBadge.aiGenerated([String label = 'AI-Generated']) =>

      StatusBadge(label: label, color: AdminTheme.danger);



  factory StatusBadge.suspicious([String label = 'Suspicious']) =>

      StatusBadge(label: label, color: const Color(0xFFEA580C));



  factory StatusBadge.needsReview([String label = 'Needs Review']) =>

      StatusBadge(label: label, color: AdminTheme.warning);



  factory StatusBadge.excellent([String label = 'Excellent']) =>

      StatusBadge(label: label, color: AdminTheme.success);



  factory StatusBadge.good([String label = 'Good']) =>

      StatusBadge(label: label, color: AdminTheme.accentBlue);



  factory StatusBadge.needsImprovement([String label = 'Needs Improvement']) =>

      StatusBadge(label: label, color: AdminTheme.warning);



  factory StatusBadge.active([String label = 'Active']) =>

      StatusBadge(label: label, color: AdminTheme.success);



  factory StatusBadge.inactive([String label = 'Inactive']) =>

      StatusBadge(label: label, color: AdminTheme.textSecondary);



  factory StatusBadge.skill(String level) {

    final color = switch (level.toLowerCase()) {

      'expert' => const Color(0xFF7C3AED),

      'advanced' => AdminTheme.accentBlue,

      'intermediate' => AdminTheme.accentCyan,

      _ => AdminTheme.textSecondary,

    };

    return StatusBadge(label: level, color: color);

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.35)),

      ),

      child: Text(

        label,

        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),

      ),

    );

  }

}

