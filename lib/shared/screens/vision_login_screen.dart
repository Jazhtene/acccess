import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/screens/registration_choice_screen.dart';
import 'package:access_mobile/shared/widgets/access_logo.dart';

/// Single login screen for Admin, Member, and Organization accounts.
/// Role detection and platform redirect happen in [AuthGate] after success.
///
/// Registration (Create Account) is shown on mobile only — not on web admin.
class VisionLoginScreen extends StatefulWidget {
  const VisionLoginScreen({super.key, this.onAuthenticated});

  /// Optional callback after successful login (auth state is also persisted).
  final void Function()? onAuthenticated;

  @override
  State<VisionLoginScreen> createState() => _VisionLoginScreenState();
}

class _VisionLoginScreenState extends State<VisionLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  /// Registration is mobile-only; web admin login stays sign-in only.
  static bool get _showCreateAccount => !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (brandingController.lastError != null) {
      brandingController.refresh();
    }
  }

  static const Color _panelNavy = Color(0xFF0A1F38);
  static const Color _panelNavyLight = Color(0xFF1E3A5F);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authController.login(email, pass);
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onAuthenticated?.call();
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == 'pending') {
          _error = 'Your account is still pending admin approval.';
        } else if (e.code == 'rejected') {
          _error =
              'Your account registration was rejected. Please contact the administrator.';
        } else if (e.code == 'removed') {
          _error = 'Your account has been removed. Please contact the administrator.';
        } else {
          _error = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openRegistrationChoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;

    return Scaffold(
      backgroundColor: kBg,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: wide ? _wideLayout(context) : _narrowLayout(context),
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _brandPanel(context, compact: false)),
        Expanded(
          child: ColoredBox(
            color: kSurface,
            child: _formPanel(context, horizontalPadding: 56, maxFormWidth: 420),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final headerHeight = (MediaQuery.sizeOf(context).height * 0.34)
        .clamp(200.0 + viewPadding.top, 300.0);

    return ColoredBox(
      color: kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: headerHeight,
            child: _brandPanel(context, compact: true),
          ),
          Expanded(
            child: _formPanel(context, horizontalPadding: 24, maxFormWidth: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel(BuildContext context, {required bool compact}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_panelNavy, _panelNavyLight, Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 48,
            vertical: compact ? 12 : 48,
          ),
          child: ListenableBuilder(
            listenable: brandingController,
            builder: (_, __) {
              final brandColumn = Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AccessLogoImage(size: compact ? 72 : 100, fit: BoxFit.contain),
                  SizedBox(height: compact ? 10 : 28),
                  Text(
                    brandingController.appName,
                    textAlign: TextAlign.center,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 20 : 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  if (compact) ...[
                    const SizedBox(height: 6),
                    Text(
                      brandingController.shortTagline,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    Text(
                      brandingController.shortTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Coordination and Documentation Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              );

              if (compact) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: brandColumn,
                  ),
                );
              }

              return brandColumn;
            },
          ),
        ),
      ),
    );
  }

  Widget _formPanel(BuildContext context, {required double horizontalPadding, required double maxFormWidth}) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 0 ? constraints.maxHeight - 64 : 0,
                maxWidth: maxFormWidth,
              ),
              child: Align(
                alignment: Alignment.center,
                child: _formContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formContent() {
    final isWebAdmin = kIsWeb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sign in',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isWebAdmin
              ? 'Administrator sign in for the ACCESS Sync web dashboard.'
              : 'Sign in with your approved member or organization account.',
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 32),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kRedDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: kRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Email', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration('you@access.edu', Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          onSubmitted: (_) => _submit(),
          decoration: _decoration(
            '••••••••',
            Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        if (_showCreateAccount) ...[
          const SizedBox(height: 20),
          _createAccountLink(),
        ],
      ],
    );
  }

  Widget _createAccountLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          GestureDetector(
            onTap: _openRegistrationChoice,
            child: const Text(
              'Create Account',
              style: TextStyle(
                color: kAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: kTextSecondary, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: kSurfaceAlt,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccent, width: 1.5)),
    );
  }
}
