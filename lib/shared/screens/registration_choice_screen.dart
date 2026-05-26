import 'package:flutter/material.dart';
import 'package:access_mobile/shared/screens/member_registration_screen.dart';
import 'package:access_mobile/shared/screens/organization_registration_screen.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/widgets/registration_form_widgets.dart';

/// Mobile-only: choose member or organization registration.
class RegistrationChoiceScreen extends StatelessWidget {
  const RegistrationChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Choose how you want to register with ACCESS Sync.',
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 24),
            RegistrationTypeCard(
              title: 'Register as Member',
              subtitle: 'For student photographers, videographers, and editors',
              icon: Icons.groups_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberRegistrationScreen()),
              ),
            ),
            const SizedBox(height: 12),
            RegistrationTypeCard(
              title: 'Register as Organization',
              subtitle: 'For clubs and orgs requesting documentation services',
              icon: Icons.business_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizationRegistrationScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
