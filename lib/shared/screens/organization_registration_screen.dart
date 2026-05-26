import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/widgets/registration_form_widgets.dart';

/// Self-service organization registration (pending admin approval).
class OrganizationRegistrationScreen extends StatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  State<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState extends State<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameCtrl = TextEditingController();
  final _orgEmailCtrl = TextEditingController();
  final _adviserCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _orgEmailCtrl.dispose();
    _adviserCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authController.register(
        name: _orgNameCtrl.text.trim(),
        email: _orgEmailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: 'Organization',
        contactNumber: _contactCtrl.text.trim(),
        adviserName: _adviserCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted! Your organization account is pending admin approval.',
          ),
          backgroundColor: kGreen,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

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
          'Register as Organization',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const Text(
                'Register your student organization to request documentation services. '
                'An administrator will review your application before you can sign in.',
                style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 20),
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
              RegistrationFormField(
                label: 'Organization Name',
                controller: _orgNameCtrl,
                hint: 'USTP Engineering Society',
                icon: Icons.business_outlined,
                validator: (v) => RegistrationValidators.required(v, label: 'Organization name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              RegistrationFormField(
                label: 'Organization Email',
                controller: _orgEmailCtrl,
                hint: 'org@ustp.edu.ph',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: RegistrationValidators.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              RegistrationFormField(
                label: 'Adviser or Representative Name',
                controller: _adviserCtrl,
                hint: 'Prof. Maria Santos',
                icon: Icons.person_outline,
                validator: (v) =>
                    RegistrationValidators.required(v, label: 'Adviser or representative name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              RegistrationFormField(
                label: 'Contact Number',
                controller: _contactCtrl,
                hint: '09XX XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => RegistrationValidators.required(v, label: 'Contact number'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              RegistrationFormField(
                label: 'Password',
                controller: _passwordCtrl,
                hint: 'At least 6 characters',
                icon: Icons.lock_outline,
                obscureText: _obscurePass,
                validator: RegistrationValidators.password,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              RegistrationFormField(
                label: 'Confirm Password',
                controller: _confirmCtrl,
                hint: 'Re-enter password',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                validator: (v) =>
                    RegistrationValidators.confirmPassword(v, _passwordCtrl.text),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
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
                      : const Text('Register', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
