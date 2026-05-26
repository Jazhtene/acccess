import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/constants/app_constants.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/widgets/access_logo.dart';
import 'package:access_mobile/web_admin/layout/admin_feature_page.dart';
import 'package:access_mobile/web_admin/layout/admin_route_breadcrumbs.dart';
import 'package:access_mobile/web_admin/navigation/admin_routes.dart';
import 'package:access_mobile/web_admin/services/file_picker_service.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';

class AdminBrandingScreen extends StatefulWidget {
  const AdminBrandingScreen({super.key});

  @override
  State<AdminBrandingScreen> createState() => _AdminBrandingScreenState();
}

class _AdminBrandingScreenState extends State<AdminBrandingScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _updatedBy;

  late final TextEditingController _appNameCtrl;
  late final TextEditingController _shortTaglineCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _orgCtrl;

  @override
  void initState() {
    super.initState();
    _appNameCtrl = TextEditingController();
    _shortTaglineCtrl = TextEditingController();
    _taglineCtrl = TextEditingController();
    _orgCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _shortTaglineCtrl.dispose();
    _taglineCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  void _fillFromBranding() {
    _appNameCtrl.text = brandingController.appName;
    _shortTaglineCtrl.text = brandingController.shortTagline;
    _taglineCtrl.text = brandingController.tagline;
    _orgCtrl.text = brandingController.organization;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await brandingController.refresh();
      final meta = await adminApi.getBranding();
      _fillFromBranding();
      if (mounted) {
        setState(() {
          _updatedBy = meta['updated_by'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('system_branding') || msg.contains('UndefinedTable') || msg.contains('app_name')) {
      return 'Database needs update. Run: cd access_backend && python migrate_branding_names.py';
    }
    if (msg.contains('failed to fetch') || msg.contains('Browser blocked')) {
      return 'Cannot reach API at ${ApiConfig.baseUrl}. '
          'Start backend: cd access_backend && python manage.py runserver';
    }
    return msg;
  }

  Future<void> _saveNames() async {
    final appName = _appNameCtrl.text.trim();
    final shortTag = _shortTaglineCtrl.text.trim();
    if (appName.isEmpty || shortTag.isEmpty) {
      setState(() => _error = 'System name and short subtitle are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await adminApi.updateBrandingNames(
        appName: appName,
        tagline: _taglineCtrl.text.trim(),
        shortTagline: shortTag,
        organization: _orgCtrl.text.trim(),
      );
      brandingController.applyPayload(result);
      if (mounted) {
        setState(() {
          _updatedBy = result['updated_by'] as String?;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System names updated on mobile and web.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _resetNames() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset system names?'),
        content: const Text(
          'Restore default names:\n'
          '• ACCESS Sync\n'
          '• Coordination and Documentation Platform',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await adminApi.resetBrandingNames();
      brandingController.applyPayload(result);
      _appNameCtrl.text = AppConstants.appName;
      _shortTaglineCtrl.text = AppConstants.shortTagline;
      _taglineCtrl.text = AppConstants.tagline;
      _orgCtrl.text = AppConstants.organization;
      if (mounted) {
        setState(() {
          _updatedBy = result['updated_by'] as String?;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System names reset to defaults.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await pickImagesFromWeb();
    if (picked.isEmpty) return;
    final file = picked.first;
    final name = file.name.toLowerCase();
    if (!name.endsWith('.jpg') &&
        !name.endsWith('.jpeg') &&
        !name.endsWith('.png') &&
        !name.endsWith('.webp')) {
      setState(() => _error = 'Use JPG, PNG, or WEBP for the logo.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await adminApi.uploadLogo(bytes: file.bytes, fileName: file.name);
      brandingController.applyUploadResult(result);
      final meta = await adminApi.getBranding();
      if (mounted) {
        setState(() {
          _updatedBy = meta['updated_by'] as String?;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated across mobile and web.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _resetLogo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset logo?'),
        content: const Text('Remove the custom logo and use the default bundled image.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await adminApi.resetLogo();
      brandingController.applyResetLogoResult(result);
      if (mounted) {
        setState(() {
          _updatedBy = null;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo reset to default.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFeaturePage(
      title: 'Branding & System Names',
      subtitle: 'Customize the ACCESS logo and display names for mobile and web.',
      breadcrumbs: breadcrumbsForRoute(AdminRoute.branding),
      actions: [
        IconButton(onPressed: _loading || _busy ? null : _load, icon: const Icon(Icons.refresh)),
      ],
      loading: _loading,
      body: ListenableBuilder(
        listenable: brandingController,
        builder: (_, __) {
          final isCustomLogo = brandingController.isCustomLogo;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewCard(isCustomLogo: isCustomLogo),
                  const SizedBox(width: 24),
                  Expanded(child: _buildNamesForm()),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Logo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickAndUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload new logo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || !isCustomLogo ? null : _resetLogo,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset logo'),
                  ),
                ],
              ),
              if (_updatedBy != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last updated by $_updatedBy',
                  style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNamesForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('System names', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              if (brandingController.namesCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Shown in sidebar, login, splash, headers, and profile.',
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _nameField('System name *', _appNameCtrl, 'ACCESS Sync'),
          const SizedBox(height: 12),
          _nameField(
            'Short subtitle *',
            _shortTaglineCtrl,
            'Coordination and Documentation Platform',
          ),
          const SizedBox(height: 12),
          _nameField('Full tagline', _taglineCtrl, AppConstants.tagline, maxLines: 2),
          const SizedBox(height: 12),
          _nameField('Organization', _orgCtrl, AppConstants.organization),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _saveNames,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save system names'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _resetNames,
                icon: const Icon(Icons.undo),
                label: const Text('Reset names to default'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nameField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.isCustomLogo});

  final bool isCustomLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        children: [
          const AccessLogoImage(size: 120),
          const SizedBox(height: 16),
          Text(
            brandingController.appName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brandingController.shortTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCustomLogo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isCustomLogo ? 'Custom logo' : 'Default logo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCustomLogo ? const Color(0xFF166534) : AdminTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
