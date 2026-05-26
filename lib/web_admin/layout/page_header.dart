import 'package:flutter/material.dart';

import 'package:access_mobile/web_admin/layout/breadcrumbs.dart';

import 'package:access_mobile/web_admin/layout/last_updated_text.dart';

import 'package:access_mobile/web_admin/layout/admin_breakpoints.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';



/// Standard admin page header — title, breadcrumbs, description, actions, last updated.

class PageHeader extends StatelessWidget {

  const PageHeader({

    super.key,

    required this.title,

    required this.subtitle,

    this.breadcrumbs = const [],

    this.actions = const [],

    this.lastUpdated,

  });



  final String title;

  final String subtitle;

  final List<String> breadcrumbs;

  final List<Widget> actions;

  final DateTime? lastUpdated;



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, c) {

        final compact = c.maxWidth < AdminBreakpoints.tablet;
        final titleSize = c.maxWidth < 430 ? 22.0 : (compact ? 24.0 : 26.0);



        final titleBlock = Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            if (breadcrumbs.isNotEmpty) ...[

              Breadcrumbs(segments: breadcrumbs),

              const SizedBox(height: 8),

            ],

            Text(

              title,

              style: TextStyle(

                fontSize: titleSize,

                fontWeight: FontWeight.w800,

                color: AdminTheme.textPrimary,

                letterSpacing: -0.5,

                height: 1.2,

              ),

            ),

            const SizedBox(height: 6),

            Text(

              subtitle,

              style: const TextStyle(

                color: AdminTheme.textSecondary,

                fontSize: 13,

                height: 1.45,

              ),

            ),

            if (lastUpdated != null) ...[

              const SizedBox(height: 6),

              LastUpdatedText(updatedAt: lastUpdated),

            ],

          ],

        );



        if (compact) {

          return Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              titleBlock,

              if (actions.isNotEmpty) ...[

                const SizedBox(height: 14),

                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: actions),

              ],

            ],

          );

        }



        return Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Expanded(child: titleBlock),

            if (actions.isNotEmpty) ...[

              const SizedBox(width: 16),

              Wrap(spacing: 8, runSpacing: 8, children: actions),

            ],

          ],

        );

      },

    );

  }

}



/// Rounded outline action for page headers.

class PageHeaderButton extends StatelessWidget {

  const PageHeaderButton({

    super.key,

    required this.label,

    required this.icon,

    required this.onPressed,

    this.filled = false,

    this.enabled = true,

  });



  final String label;

  final IconData icon;

  final VoidCallback? onPressed;

  final bool filled;

  final bool enabled;



  @override

  Widget build(BuildContext context) {

    if (filled) {

      return FilledButton.icon(

        onPressed: enabled ? onPressed : null,

        icon: Icon(icon, size: 18),

        label: Text(label),

      );

    }

    return OutlinedButton.icon(

      onPressed: enabled ? onPressed : null,

      style: OutlinedButton.styleFrom(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      ),

      icon: Icon(icon, size: 18),

      label: Text(label),

    );

  }

}



class PageHeaderIconButton extends StatelessWidget {

  const PageHeaderIconButton({

    super.key,

    required this.icon,

    required this.onPressed,

    this.tooltip,

    this.enabled = true,

  });



  final IconData icon;

  final VoidCallback? onPressed;

  final String? tooltip;

  final bool enabled;



  @override

  Widget build(BuildContext context) {

    return IconButton.filledTonal(

      onPressed: enabled ? onPressed : null,

      icon: Icon(icon, size: 20),

      tooltip: tooltip ?? 'Refresh',

      style: IconButton.styleFrom(

        backgroundColor: Colors.white,

        foregroundColor: AdminTheme.textPrimary,

        disabledForegroundColor: AdminTheme.textSecondary,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(10),

          side: const BorderSide(color: AdminTheme.border),

        ),

      ),

    );

  }

}

