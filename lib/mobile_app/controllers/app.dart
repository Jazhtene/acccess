import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/shared/widgets/auth_gate.dart';
import 'package:access_mobile/mobile_app/screens/dashboard_screen.dart';
import 'package:access_mobile/mobile_app/screens/calendar_screen.dart';
import 'package:access_mobile/mobile_app/screens/evaluation_screen.dart';
import 'package:access_mobile/mobile_app/screens/rankings_screen.dart';
import 'package:access_mobile/mobile_app/screens/feedback_screen.dart';
import 'package:access_mobile/mobile_app/screens/profile_screen.dart';
import 'package:access_mobile/mobile_app/screens/service_requests_screen.dart';
import 'package:access_mobile/mobile_app/sheets/facebook_share_sheet.dart';
import 'package:access_mobile/mobile_app/sheets/notifications_sheet.dart';
import 'package:access_mobile/mobile_app/widgets/ai_detected_badge.dart';
import 'package:access_mobile/shared/widgets/access_branding.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_ui_kit.dart';
import 'package:access_mobile/mobile_app/widgets/mobile_splash_gate.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/web_admin/controllers/web_admin_shell.dart';
class AccessApp extends StatefulWidget {
  const AccessApp({super.key});
  @override
  State<AccessApp> createState() => _AccessAppState();
}

// Legacy account type for mobile shells (maps from API roles).
enum AccountType { member, requester }

class _AccessAppState extends State<AccessApp> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appState, brandingController]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: brandingController.mobileTitle,
        theme: buildAccessLightTheme(),
        darkTheme: buildAccessDarkTheme(),
        // Mobile uses the clean light ACCESS palette (matches design tokens).
        themeMode: kIsWeb ? appState.themeMode : ThemeMode.light,
        home: MobileSplashGate(
          child: AuthGate(
            adminBuilder: (user) => kIsWeb
                ? WebAdminShell(user: user)
                : MainShell(
                    onLogout: authController.logout,
                    userName: user.name,
                  ),
            memberBuilder: (user) => MainShell(
              onLogout: authController.logout,
              userName: user.name,
            ),
            organizationBuilder: (user) => RequesterShell(
              onLogout: authController.logout,
              userName: user.name,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// Order MUST match _MainShellState._screen so the bottom-nav icon, label and
// destination stay in sync. Indices that don't render in the bottom nav
// (Feedback) are still kept here so the side rail (if shown) is consistent.
//
// Icons follow the project icon contract — all rounded variants for visual
// consistency. See lib/shared/themes/theme.dart for the color tokens.
const _navItems = [
  _NavItem(Icons.dashboard_rounded,       'Home'),         // 0
  _NavItem(Icons.analytics_rounded,       'Evaluations'),  // 1
  _NavItem(Icons.calendar_month_rounded,  'Calendar'),     // 2
  _NavItem(Icons.photo_library_rounded,   'Gallery'),      // 3
  _NavItem(Icons.rate_review_rounded,     'Feedback'),     // 4
  _NavItem(Icons.emoji_events_rounded,    'Rankings'),     // 5
  _NavItem(Icons.person_rounded,          'Profile'),      // 6
];

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  const MainShell({super.key, required this.onLogout, required this.userName});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapData();
  }

  Future<void> _bootstrapData() async {
    await memberDataController.refreshAll();
    await brandingController.refresh();
  }

  Widget get _screen => switch (_navIndex) {
    0 => const DashboardScreen(),
    1 => const EvaluationScreen(),
    2 => const CalendarScreen(),
    3 => const _GalleryScreenWrapper(),
    4 => const FeedbackScreen(),
    5 => const RankingsScreen(),
    6 => const ProfileScreen(),
    _ => const DashboardScreen(),
  };

  String get _userInitials {
    final n = widget.userName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(children: [
          _TopBar(
            userName: widget.userName,
            userInitials: _userInitials,
            onNotifications: () => showNotifications(context),
            onLogout: widget.onLogout),
          Expanded(
            child: MobilePageWrapper(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_navIndex),
                  child: _screen,
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _MobileBottomNav(
        selected: _navIndex,
        onTap: (i) => setState(() => _navIndex = i)),
    );
  }
}

// The legacy side rail was removed — the mobile shell uses _MobileBottomNav
// on every form factor. The web admin has its own shell under lib/web_admin/.
// Do not re-introduce a side rail here without keeping _navItems and the
// bottom-nav slot mapping in sync.

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String userName;
  final String userInitials;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;
  const _TopBar({
    required this.userName,
    required this.userInitials,
    required this.onNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 340;
    return Container(
      height: compact ? 58 : 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: compact
              ? const AccessBrandMark.iconOnly(logoSize: 42)
              : const AccessHeaderBrand(logoSize: 40),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: appState,
          builder: (_, __) => GestureDetector(
            onTap: onNotifications,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: kIconInactive, size: 20),
              ),
              if (appState.unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        appState.unreadCount > 9 ? '9+' : '${appState.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showLogoutMenu(context),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: kAccent,
            child: Text(
              userInitials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showLogoutMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: context.colors.border,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: kAccent,
                child: Text(userInitials, style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: TextStyle(color: context.colors.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w700)),
                Text(appState.profileTitle ?? 'ACCESS Member',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Divider(color: context.colors.border, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: kRed),
            title: const Text('Sign Out',
              style: TextStyle(color: kRed, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); onLogout(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Mobile bottom nav ─────────────────────────────────────────────────────────
class _MobileBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _MobileBottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const slots = [
      (0, 'Home'),
      (1, 'Evaluations'),
      (2, 'Calendar'),
      (3, 'Gallery'),
      (5, 'Rankings'),
      (6, 'Profile'),
    ];

    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: slots.map((slot) {
                final idx = slot.$1;
                final item = _navItems[idx];
                final active = idx == selected;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(idx),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: active
                              ? kAccent.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: active ? kAccent : kIconInactive,
                              size: active ? 24 : 22,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                slot.$2,
                                maxLines: 1,
                                style: TextStyle(
                                  color: active ? kAccent : kIconInactive,
                                  fontSize: 10,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Requester Shell (separate app for service requesters) ─────────────────────
// ── Requester Shell ───────────────────────────────────────────────────────────
class RequesterShell extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  const RequesterShell({super.key, required this.onLogout, required this.userName});
  @override
  State<RequesterShell> createState() => _RequesterShellState();
}

class _RequesterShellState extends State<RequesterShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ServiceRequestsScreen(requesterName: widget.userName),
      const FeedbackScreen(),
      const _RequesterGallery(),
    ];
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(children: [
          _RequesterTopBar(userName: widget.userName, onLogout: widget.onLogout),
          Expanded(child: screens[_index]),
        ]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _RequesterTab(
                  icon: Icons.send_rounded,
                  label: 'Requests',
                  active: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _RequesterTab(
                  icon: Icons.rate_review_rounded,
                  label: 'Feedback',
                  active: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _RequesterTab(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  active: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequesterTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _RequesterTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kAccent.withValues(alpha: 0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: active ? kAccent : kIconInactive, size: active ? 24 : 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? kAccent : kIconInactive,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RequesterTopBar extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  const _RequesterTopBar({required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(bottom: BorderSide(color: context.colors.border))),
    child: Row(children: [
      compact
          ? const AccessBrandMark.iconOnly(logoSize: 32)
          : const AccessHeaderBrand(logoSize: 30, title: 'Service Portal'),
      const Spacer(),
      // Notification bell
      ListenableBuilder(
        listenable: appState,
        builder: (_, __) => GestureDetector(
          onTap: () => showNotifications(context),
          child: Stack(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: context.colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.border)),
              child: const Icon(Icons.notifications_none_rounded,
                color: kIconInactive, size: 18)),
            if (appState.unreadCount > 0)
              Positioned(top: 0, right: 0,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                  child: Center(child: Text('${appState.unreadCount}',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.w700))))),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      CircleAvatar(radius: 14, backgroundColor: kGreen,
        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: kRedDim,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kRed.withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.logout, color: kRed, size: 14),
            SizedBox(width: 4),
            Text('Sign Out', style: TextStyle(color: kRed,
              fontSize: 11, fontWeight: FontWeight.w600)),
          ]))),
    ]),
  );
  }
}

Widget _galleryPlaceholder(GalleryItem item) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [item.color, item.color.withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        item.isVideo ? Icons.videocam : Icons.photo_library,
        color: Colors.white.withOpacity(0.7),
        size: 32,
      ),
    ),
  );
}

// ── Gallery inline screen ─────────────────────────────────────────────────────
class _GalleryScreenWrapper extends StatefulWidget {
  const _GalleryScreenWrapper();
  @override
  State<_GalleryScreenWrapper> createState() => _GalleryScreenWrapperState();
}

class _GalleryScreenWrapperState extends State<_GalleryScreenWrapper> {
  String _filter = 'All Media';
  final _picker = ImagePicker();

  static const _filters = [
    'All Media', 'Photos', 'Videos', 'Events', 'Evaluated', 'Needs Review',
  ];

  Future<void> _pickPhotos() async {
    final requestId = memberDataController.defaultRequestId;
    if (requestId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No assigned task yet. Ask admin to assign a documentation request.'),
          backgroundColor: kRed));
      }
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    try {
      for (final f in picked) {
        final bytes = await f.readAsBytes();
        await memberDataController.uploadMedia(
          bytes: bytes,
          fileName: f.name,
          requestId: requestId,
          title: f.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
        );
      }
      if (mounted) showMobileToast(context, 'Uploaded successfully');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: kRed));
      }
    }
  }

  Future<void> _pickVideo() async {
    final requestId = memberDataController.defaultRequestId;
    if (requestId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No assigned task yet.'),
          backgroundColor: kRed));
      }
      return;
    }
    final picked = await _picker.pickVideo(source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2));
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      await memberDataController.uploadMedia(
        bytes: bytes,
        fileName: picked.name,
        requestId: requestId,
        title: picked.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Video uploaded to server'), backgroundColor: kGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: kRed));
      }
    }
  }

  List<GalleryItem> get _filtered {
    final all = appState.gallery;
    switch (_filter) {
      case 'Photos':
        return all.where((g) => !g.isVideo).toList();
      case 'Videos':
        return all.where((g) => g.isVideo).toList();
      case 'Events':
        return all.where((g) => g.category.toLowerCase().contains('event')).toList();
      case 'Evaluated':
        return all.where((g) => g.mediaId != null).toList();
      case 'Needs Review':
        return all.where((g) => g.mediaId == null || g.aiDetected).toList();
      default:
        return all;
    }
  }

  String _evalStatus(GalleryItem item) {
    if (item.aiDetected) return 'Needs review';
    if (item.mediaId != null) return 'Evaluated';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appState, memberDataController]),
      builder: (_, __) {
        if (memberDataController.isLoading && appState.gallery.isEmpty) {
          return const MobileLoadingView(message: 'Loading gallery…');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MobilePageTitle(
              title: 'Gallery',
              subtitle: 'Upload event photos and videos for VisionCheck evaluation.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kMobilePagePadding),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAccent,
                        side: const BorderSide(color: kAccent),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_outlined, size: 18),
                      label: const Text('Upload Video', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kMobilePagePadding),
              child: GestureDetector(
                onTap: _pickPhotos,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_rounded, color: context.colors.textSecondary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload media',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Images: JPG, PNG  ·  Videos: MP4, MOV  ·  Max 50 MB per file',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            MobileFilterChips(
              filters: _filters,
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const MobileEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'No media yet',
                      subtitle: 'Upload photos or videos for your assigned events.',
                    )
                  : RefreshIndicator(
                      color: kAccent,
                      onRefresh: () => memberDataController.refreshAll(),
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(kMobilePagePadding, 0, kMobilePagePadding, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final status = _evalStatus(item);
                          final statusColor = status == 'Evaluated'
                              ? kGreen
                              : status == 'Needs review'
                                  ? kOrange
                                  : kYellow;
                          return GestureDetector(
                            onTap: () => _openGalleryItem(context, item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          item.networkUrl != null
                                              ? Image.network(
                                                  item.networkUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _galleryPlaceholder(item),
                                                )
                                              : item.imageBytes != null
                                                  ? Image.memory(item.imageBytes!, fit: BoxFit.cover)
                                                  : _galleryPlaceholder(item),
                                          if (item.isVideo)
                                            Container(
                                              color: Colors.black26,
                                              child: const Center(
                                                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                                              ),
                                            ),
                                          if (item.aiDetected) const AiDetectedBadge(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: context.colors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: context.colors.textSecondary, fontSize: 10),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.date,
                                          style: TextStyle(color: context.colors.textSecondary, fontSize: 10),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DropBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DropBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: context.colors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.colors.textPrimary,
          fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

void _openGalleryItem(BuildContext context, GalleryItem item) {
  if (item.isVideo) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _VideoViewScreen(item: item)));
  } else {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white,
          title: Text(item.title, style: const TextStyle(fontSize: 14)),
          actions: [
            IconButton(
              icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
              onPressed: () => shareGalleryItemToFacebook(context, item),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, color: kRed),
              onPressed: () {
                appState.gallery.remove(item);
                appState.notifyListeners();
                Navigator.pop(context);
              }),
          ]),
        body: Center(child: item.networkUrl != null
          ? InteractiveViewer(child: Image.network(item.networkUrl!))
          : item.imageBytes != null
          ? InteractiveViewer(child: Image.memory(item.imageBytes!))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.photo_library, color: item.color, size: 80),
              const SizedBox(height: 16),
              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ])),
      )));
  }
}

class _VideoViewScreen extends StatelessWidget {
  final GalleryItem item;
  const _VideoViewScreen({required this.item});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black, foregroundColor: Colors.white,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: const TextStyle(fontSize: 14)),
        Text('Video · ${item.date}',
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline, color: kRed),
          onPressed: () {
            appState.gallery.remove(item);
            appState.notifyListeners();
            Navigator.pop(context);
          }),
      ]),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: kPurple.withOpacity(0.2), shape: BoxShape.circle,
          border: Border.all(color: kPurple, width: 2)),
        child: const Icon(Icons.play_arrow, color: kPurple, size: 56)),
      const SizedBox(height: 20),
      const Text('Video ready', style: TextStyle(color: Colors.white,
        fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (item.videoPath != null)
        Text(item.videoPath!.split('/').last,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center),
    ])),
  );
}

// ── Requester Gallery (read-only view of members' gallery) ────────────────────
class _RequesterGallery extends StatefulWidget {
  const _RequesterGallery();
  @override
  State<_RequesterGallery> createState() => _RequesterGalleryState();
}

class _RequesterGalleryState extends State<_RequesterGallery> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final categories = ['All', ...{for (final g in appState.gallery) g.category}];
        final filtered = _filter == 'All'
          ? appState.gallery
          : appState.gallery.where((g) => g.category == _filter).toList();

        return Column(children: [
          // Header
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Event Gallery', style: TextStyle(color: context.colors.textPrimary,
                fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Browse ACCESS event photos.',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              // Filter chips
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final active = cat == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? kAccent : context.colors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? kAccent : context.colors.border)),
                        child: Text(cat, style: TextStyle(
                          color: active ? Colors.white : context.colors.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w600))),
                    );
                  },
                ),
              ),
            ]),
          ),

          // Grid
          Expanded(
            child: filtered.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, color: context.colors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text('No photos yet', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                  ]))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 10,
                    mainAxisSpacing: 10, childAspectRatio: 1.0),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return GestureDetector(
                      onTap: () => _openItem(context, item),
                      child: Container(
                        decoration: BoxDecoration(color: context.colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.colors.border)),
                        child: Column(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Stack(fit: StackFit.expand, children: [
                              item.imageBytes != null
                                ? Image.memory(item.imageBytes!,
                                    width: double.infinity, fit: BoxFit.cover)
                                : Container(
                                    color: item.isVideo
                                      ? kPurple.withOpacity(0.15)
                                      : item.color.withOpacity(0.15),
                                    child: Center(child: Icon(
                                      item.isVideo ? Icons.videocam : Icons.photo_library,
                                      color: item.isVideo ? kPurple : item.color, size: 36))),
                              if (item.isVideo)
                                Container(color: Colors.black26,
                                  child: const Center(child: Icon(
                                    Icons.play_circle_fill, color: Colors.white, size: 40))),
                              if (item.aiDetected) const AiDetectedBadge(),
                            ]))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.title, style: TextStyle(color: context.colors.textPrimary,
                                fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                item.isVideo ? 'Video · ${item.date}' : '${item.category} · ${item.date}',
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 9)),
                            ])),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ]);
      },
    );
  }

  void _openItem(BuildContext context, GalleryItem item) {
    _openGalleryItem(context, item);
  }
}
