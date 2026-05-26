import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/services/file_picker_service.dart';
import 'package:access_mobile/web_admin/widgets/admin_shell_scaffold.dart';

class AdminUploadMediaScreen extends StatefulWidget {
  const AdminUploadMediaScreen({super.key});

  @override
  State<AdminUploadMediaScreen> createState() => _AdminUploadMediaScreenState();
}

class _AdminUploadMediaScreenState extends State<AdminUploadMediaScreen> {
  List<Map<String, dynamic>> _requests = [];
  int? _requestId;
  bool _uploading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final list = await adminApi.allServiceRequests();
      final approved = list.where((r) =>
          (r['status'] as String? ?? '').toLowerCase() == 'approved').toList();
      if (mounted) {
        setState(() {
          _requests = approved.isNotEmpty ? approved : list;
          if (_requests.isNotEmpty) {
            _requestId = _requests.first['request_id'] as int?;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAndUpload() async {
    if (_requestId == null) {
      setState(() => _message = 'Select an approved documentation request first.');
      return;
    }
    final picked = await pickImagesFromWeb();
    if (picked.isEmpty) return;
    setState(() {
      _uploading = true;
      _message = null;
    });
    try {
      for (final f in picked) {
        await adminApi.uploadMedia(
          bytes: f.bytes,
          fileName: f.name,
          requestId: _requestId!,
          displayName: f.name,
        );
      }
      if (mounted) {
        setState(() {
          _uploading = false;
          _message = 'Uploaded ${picked.length} file(s) to database.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellScaffold(
      title: 'Upload Media',
      subtitle: 'Saves to media_files + runs evaluation pipeline.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Documentation request', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _requestId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _requests
                .map((r) => DropdownMenuItem(
                      value: r['request_id'] as int,
                      child: Text(r['title'] as String? ?? 'Request ${r['request_id']}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _requestId = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_uploading ? 'Uploading…' : 'Choose files & upload'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: TextStyle(color: _message!.contains('Uploaded') ? Colors.green : Colors.red)),
          ],
        ],
      ),
    );
  }
}
