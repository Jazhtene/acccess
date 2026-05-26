import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/api/member_api_service.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/widgets/registration_form_widgets.dart';

/// Edit the logged-in member's profile (mobile only).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _adviserCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _showPasswordFields = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _profileImageUrl;
  bool _isMember = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _studentIdCtrl.dispose();
    _adviserCtrl.dispose();
    _roleCtrl.dispose();
    _statusCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await memberApiService.getProfile();
      if (!mounted) return;
      final role = profile['role'] as String? ?? 'Member';
      _isMember = role.toLowerCase() == 'member';
      _nameCtrl.text = profile['name'] as String? ?? '';
      _emailCtrl.text = profile['email'] as String? ?? '';
      _contactCtrl.text = profile['contact_number'] as String? ?? '';
      _studentIdCtrl.text = profile['student_id'] as String? ?? '—';
      _adviserCtrl.text = profile['adviser_name'] as String? ?? '—';
      _roleCtrl.text = role;
      _statusCtrl.text = _statusLabel(profile['status'] as String? ?? 'approved');
      final img = profile['profile_image'] as String?;
      _profileImageUrl = img != null ? memberApiService.mediaUrl(img) : null;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _statusLabel(String status) {
    return switch (status.toLowerCase()) {
      'pending' => 'Pending approval',
      'rejected' => 'Rejected',
      _ => 'Approved',
    };
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final bytes = await file.readAsBytes();
      final updated = await memberApiService.uploadProfileAvatar(
        bytes: bytes,
        fileName: file.name,
      );
      final path = updated['profile_image'] as String?;
      setState(() {
        _profileImageUrl = path != null ? memberApiService.mediaUrl(path) : null;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated'), backgroundColor: kGreen),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kRed),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    if (_showPasswordFields && newPass.isNotEmpty) {
      if (newPass != confirmPass) {
        setState(() => _error = 'New password and confirm password do not match.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await memberApiService.updateProfile(
        name: _isMember ? _nameCtrl.text.trim() : null,
        email: _emailCtrl.text.trim(),
        contactNumber: _contactCtrl.text.trim(),
        newPassword: _showPasswordFields && newPass.isNotEmpty ? newPass : null,
      );

      await authController.updateSessionProfile(
        name: updated['name'] as String?,
        email: updated['email'] as String?,
      );

      final imagePath = updated['profile_image'] as String?;
      appState.applyProfile(
        name: updated['name'] as String? ?? _nameCtrl.text.trim(),
        email: updated['email'] as String? ?? _emailCtrl.text.trim(),
        contactNumber: updated['contact_number'] as String?,
        studentId: updated['student_id'] as String?,
        profileImage: imagePath != null ? ApiConfig.mediaUrl(imagePath) : _profileImageUrl,
        role: updated['role'] as String?,
        status: updated['status'] as String?,
        uploads: updated['uploads_count'] as int?,
        skillLevel: updated['skill_level'] as String?,
        points: updated['total_points'] as int?,
        rankPosition: updated['rank_position'] as int?,
      );

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: kGreen,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _saving = false;
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
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kRedDim,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kRed.withValues(alpha: 0.4)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: kAccent.withValues(alpha: 0.15),
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Text(
                                    appState.profileInitials,
                                    style: const TextStyle(
                                      color: kAccent,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: kAccent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _saving ? null : _pickAvatar,
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _saving ? null : _pickAvatar,
                        child: const Text('Change photo'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isMember) ...[
                      RegistrationFormField(
                        label: 'Full Name',
                        controller: _nameCtrl,
                        icon: Icons.person_outline,
                        validator: (v) => RegistrationValidators.required(v, label: 'Full name'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      _readOnlyField(
                        label: 'Organization Name',
                        controller: _nameCtrl,
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 14),
                      _readOnlyField(
                        label: 'Adviser / Representative',
                        controller: _adviserCtrl,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                    ],
                    RegistrationFormField(
                      label: 'Email',
                      controller: _emailCtrl,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: RegistrationValidators.email,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    RegistrationFormField(
                      label: 'Contact Number',
                      controller: _contactCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => RegistrationValidators.required(v, label: 'Contact number'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    if (_isMember) ...[
                      _readOnlyField(label: 'Student ID', controller: _studentIdCtrl, icon: Icons.badge_outlined),
                      const SizedBox(height: 14),
                    ],
                    _readOnlyField(label: 'Role', controller: _roleCtrl, icon: Icons.shield_outlined),
                    const SizedBox(height: 14),
                    _readOnlyField(label: 'Account Status', controller: _statusCtrl, icon: Icons.info_outline),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => setState(() => _showPasswordFields = !_showPasswordFields),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _showPasswordFields ? Icons.expand_less : Icons.expand_more,
                              color: kAccent,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Change password (optional)',
                              style: TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showPasswordFields) ...[
                      const SizedBox(height: 8),
                      RegistrationFormField(
                        label: 'New Password',
                        controller: _newPassCtrl,
                        icon: Icons.lock_outline,
                        obscureText: _obscureNew,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          return RegistrationValidators.password(v);
                        },
                        suffix: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RegistrationFormField(
                        label: 'Confirm New Password',
                        controller: _confirmPassCtrl,
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        validator: (v) {
                          if (_newPassCtrl.text.isEmpty) return null;
                          return RegistrationValidators.confirmPassword(v, _newPassCtrl.text);
                        },
                        suffix: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ],
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
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kTextSecondary, size: 18),
            filled: true,
            fillColor: kSurfaceAlt,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
          ),
        ),
      ],
    );
  }
}
