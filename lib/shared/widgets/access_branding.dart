import 'package:flutter/material.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/widgets/access_logo.dart';

Widget _brandLogo(double size, {bool avatarStyle = false}) => AccessLogoImage(
      size: size,
      avatarStyle: avatarStyle,
      circular: avatarStyle,
      fit: BoxFit.contain,
    );

enum AccessBrandLayout { horizontal, vertical }

enum AccessBrandTheme { light, dark }

/// Responsive branding — logo + configurable system name + subtitle.
class AccessBrandMark extends StatelessWidget {
  const AccessBrandMark({
    super.key,
    this.logoSize = 48,
    this.compact = false,
    this.showTagline = true,
    this.layout = AccessBrandLayout.horizontal,
    this.theme = AccessBrandTheme.dark,
    this.alignment = CrossAxisAlignment.start,
  });

  const AccessBrandMark.iconOnly({super.key, this.logoSize = 42})
      : compact = true,
        showTagline = false,
        layout = AccessBrandLayout.horizontal,
        theme = AccessBrandTheme.dark,
        alignment = CrossAxisAlignment.center;

  final double logoSize;
  final bool compact;
  final bool showTagline;
  final AccessBrandLayout layout;
  final AccessBrandTheme theme;
  final CrossAxisAlignment alignment;

  Color get _titleColor => theme == AccessBrandTheme.dark ? Colors.white : const Color(0xFF0F2744);
  Color get _subtitleColor =>
      theme == AccessBrandTheme.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: brandingController,
      builder: (_, __) {
        final logo = _brandLogo(logoSize);
        if (compact) return logo;

        final textBlock = Column(
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              brandingController.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _titleColor,
                fontSize: layout == AccessBrandLayout.vertical ? 20 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                height: 1.15,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                brandingController.shortTagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _subtitleColor,
                  fontSize: layout == AccessBrandLayout.vertical ? 12 : 10,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ],
        );

        if (layout == AccessBrandLayout.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(height: 14),
              textBlock,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Flexible(child: textBlock),
          ],
        );
      },
    );
  }
}

/// Compact inline logo + title for page headers and top bars.
class AccessHeaderBrand extends StatelessWidget {
  const AccessHeaderBrand({
    super.key,
    this.title,
    this.logoSize = 40,
    this.theme = AccessBrandTheme.light,
  });

  final String? title;
  final double logoSize;
  final AccessBrandTheme theme;

  @override
  Widget build(BuildContext context) {
    final titleColor = theme == AccessBrandTheme.dark ? Colors.white : const Color(0xFF0F2744);
    final subtitleColor = theme == AccessBrandTheme.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ListenableBuilder(
      listenable: brandingController,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandLogo(logoSize),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? brandingController.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  brandingController.shortTagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtitleColor, fontSize: 10, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
