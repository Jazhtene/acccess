import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/web_admin/widgets/admin_shell_scaffold.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await adminApi.allTasks();
      if (mounted) setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellScaffold(
      title: 'Task Assignments',
      subtitle: 'request_assignments linked to documentation_requests.',
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('No assignments yet.'))
              : ListView.separated(
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _rows[i];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      title: Text(r['request_title'] as String? ?? ''),
                      subtitle: Text(
                        '${r['member_name']} · ${r['task_role']} · ${r['event_date'] ?? ''}',
                      ),
                      trailing: Chip(label: Text(r['status'] as String? ?? '')),
                    );
                  },
                ),
    );
  }
}
