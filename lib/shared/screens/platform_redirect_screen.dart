import 'package:flutter/material.dart';
import 'package:access_mobile/shared/models/user_model.dart';
import 'package:access_mobile/shared/themes/theme.dart';

/// Shown when a user signs in on the wrong platform for their role.
class PlatformRedirectScreen extends StatelessWidget {
  const PlatformRedirectScreen({
    super.key,
    required this.user,
    required this.expectedPlatform,
    required this.onLogout,
  });

  final AuthUser user;
  final String expectedPlatform;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccent.withOpacity(0.35), width: 2),
                ),
                child: const Icon(Icons.devices, color: kAccent, size: 44),
              ),
              const SizedBox(height: 28),
              Text(
                'Hello, ${user.name}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your ${user.role.apiValue} account is configured for $expectedPlatform.\n\n'
                'Please sign in using the correct platform to access your dashboard.',
                style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onLogout,
                  child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
