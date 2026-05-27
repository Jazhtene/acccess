import 'package:flutter/material.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';

/// Standard horizontal padding for mobile tab content.
const double kMobilePagePadding = 16;

/// Vertical gap between major sections on tab screens.
const double kMobileSectionGap = 16;

/// Minimum touch height for tappable controls (Material guideline).
const double kMobileMinTouch = 44;

/// Wraps tab body with pull-to-refresh and optional offline banner.
class MobilePageWrapper extends StatelessWidget {
  const MobilePageWrapper({
    super.key,
    required this.child,
    this.showOffline = true,
  });

  final Widget child;
  final bool showOffline;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: memberDataController,
      builder: (_, __) {
        final hasError = appState.memberSyncError != null;
        final offline = showOffline && hasError && !memberDataController.isLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline)
              MobileOfflineBanner(
                error: appState.memberSyncError,
                onRetry: () => memberDataController.refreshAll(),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

Future<void> refreshMemberData(BuildContext context) async {
  await memberDataController.refreshAll();
  if (context.mounted) showMobileToast(context, 'Data updated');
}

class MobileOfflineBanner extends StatelessWidget {
  const MobileOfflineBanner({super.key, this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final body = error ?? 'Sync issue — pull down to retry.';
    final accentSoft = kAccent.withValues(alpha: 0.08);
    final accentLine = kAccent.withValues(alpha: 0.22);
    return Material(
      color: accentSoft,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: accentLine)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_off_rounded, color: kAccent, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Can't reach backend",
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      body.split('\n').first,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: kAccent,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Row(children: [
          const Icon(Icons.cloud_off_rounded, color: kYellow, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Backend unreachable',
              style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
            ),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? 'Unable to load data.',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostics',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      ApiConfig.describe(),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '• Start backend on PC: cd access_backend && python manage.py runserver\n'
                '• Android emulator → use 10.0.2.2 (default)\n'
                '• Physical phone → set the PC LAN IPv4 below.',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 11, height: 1.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final changed = await showBackendUrlDialog(context);
                  if (changed && onRetry != null) onRetry!();
                },
                icon: const Icon(Icons.dns_outlined, size: 16),
                label: const Text('Set backend URL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccent,
                  side: const BorderSide(color: kAccent),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccent),
              onPressed: () {
                Navigator.pop(context);
                onRetry!();
              },
              child: const Text('Retry now'),
            ),
        ],
      ),
    );
  }
}

/// Lets the user paste the PC's LAN IPv4 (e.g. `192.168.1.42` or
/// `192.168.1.42:3001`) and saves it as the active backend host.
///
/// Returns `true` if the user saved a new value.
Future<bool> showBackendUrlDialog(BuildContext context) async {
  final controller = TextEditingController(
    text: ApiConfig.runtimeBaseUrl.value ?? '',
  );
  String? errorText;
  bool saved = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> handleSave() async {
            final raw = controller.text.trim();
            if (raw.isEmpty) {
              setLocal(() => errorText = 'Enter the PC IPv4, e.g. 192.168.1.42');
              return;
            }
            await ApiConfig.runtimeBaseUrl.save(raw);
            if (ApiConfig.runtimeBaseUrl.value == null) {
              setLocal(() => errorText =
                  'Could not parse. Try `192.168.1.42` or `http://192.168.1.42:3001`.');
              return;
            }
            saved = true;
            if (ctx.mounted) Navigator.pop(ctx);
          }

          return AlertDialog(
            backgroundColor: ctx.colors.surface,
            title: Text(
              'Backend URL',
              style: TextStyle(color: ctx.colors.textPrimary, fontSize: 16),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Type your computer's LAN IPv4. On Windows run "
                  '`ipconfig` and copy "IPv4 Address" from your Wi-Fi adapter.',
                  style: TextStyle(
                    color: ctx.colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  style: TextStyle(color: ctx.colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '192.168.1.42  or  http://192.168.1.42:3001',
                    hintStyle: TextStyle(color: ctx.colors.textSecondary, fontSize: 12),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.dns_outlined, size: 18),
                  ),
                  onChanged: (_) {
                    if (errorText != null) setLocal(() => errorText = null);
                  },
                  onSubmitted: (_) => handleSave(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Default port is ${ApiConfig.defaultPort}.',
                  style: TextStyle(color: ctx.colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            actions: [
              if (ApiConfig.runtimeBaseUrl.value != null)
                TextButton(
                  onPressed: () async {
                    await ApiConfig.runtimeBaseUrl.clear();
                    saved = true;
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(foregroundColor: kRed),
                  child: const Text('Use default'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                onPressed: handleSave,
                child: const Text('Save & retry'),
              ),
            ],
          );
        },
      );
    },
  );

  return saved;
}

class MobilePageTitle extends StatelessWidget {
  const MobilePageTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 12, kMobilePagePadding, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      );
}

class MobileLoadingView extends StatelessWidget {
  const MobileLoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: kAccent),
            ),
            const SizedBox(height: 14),
            Text(message, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

class MobileEmptyState extends StatelessWidget {
  const MobileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: context.colors.textSecondary.withValues(alpha: 0.6)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAccent,
                    side: BorderSide(color: kAccent.withValues(alpha: 0.45)),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}

class MobileErrorState extends StatelessWidget {
  const MobileErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: kRed, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      );
}

class MobileFilterChips extends StatelessWidget {
  const MobileFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: kMobilePagePadding),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = filters[i];
            final active = f == selected;
            return GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? kAccent : context.colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: active ? kAccent : context.colors.border,
                    width: active ? 1 : 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: kAccent.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: active ? Colors.white : context.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class MobilePrimaryButton extends StatelessWidget {
  const MobilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Standard elevated surface card (dashboard sections, forms, lists).
class MobileContentCard extends StatelessWidget {
  const MobileContentCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(14);
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(color: colors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

void showMobileToast(BuildContext context, String message, {bool success = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.info_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: success ? kGreen : kAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<bool> showMobileConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(title, style: TextStyle(color: context.colors.textPrimary)),
      content: Text(message, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: destructive ? kRed : kAccent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
