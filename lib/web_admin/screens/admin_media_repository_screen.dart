import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/admin_api_service.dart';
import 'package:access_mobile/shared/api/backend_health.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/services/facebook_share_flow.dart';
import 'package:access_mobile/web_admin/services/file_picker_service.dart';
import 'package:access_mobile/web_admin/theme/admin_theme.dart';
import 'package:access_mobile/web_admin/widgets/admin_pill_tabs.dart';
import 'package:access_mobile/web_admin/widgets/admin_upload_zone.dart';

/// Gallery — view, upload, and share media from the database.
class AdminMediaRepositoryScreen extends StatefulWidget {
  const AdminMediaRepositoryScreen({super.key});

  @override
  State<AdminMediaRepositoryScreen> createState() => _AdminMediaRepositoryScreenState();
}

class _AdminMediaRepositoryScreenState extends State<AdminMediaRepositoryScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All Photos';
  bool _uploading = false;
  bool _sharing = false;

  static const _filters = ['All Photos', 'Photos', 'Videos', 'Events', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final online = await BackendHealth.isReachable();
      if (!online) {
        throw Exception(
          'Backend offline at ${ApiConfig.baseUrl}. '
          'Run: cd access_backend && python manage.py runserver',
        );
      }

      final list = await adminApi.allMedia();
      final reqs = await adminApi.allServiceRequests();

      if (mounted) {
        setState(() {
          _items = list;
          _requests = reqs.where((r) => (r['status'] as String?)?.toLowerCase() == 'approved').toList();
          if (_requests.isEmpty) _requests = reqs;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case 'Photos':
        return _items.where((m) => m['file_type'] != 'video').toList();
      case 'Videos':
        return _items.where((m) => m['file_type'] == 'video').toList();
      default:
        return _items;
    }
  }

  Future<void> _shareToFacebook() async {
    if (_filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No media to share. Upload a photo first.')),
      );
      return;
    }

    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Share to Facebook'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Opens Facebook in your browser so you can post the photo.',
              style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
          ),
          ..._filtered.take(12).map(
            (item) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, item),
              child: Text(item['file_name'] as String? ?? 'Media #${item['id']}'),
            ),
          ),
        ],
      ),
    );

    if (picked == null) return;
    final mediaId = picked['id'] as int?;
    if (mediaId == null) return;

    final imageUrl = AdminApiService.mediaUrl(picked['file_url'] as String?);
    final title = picked['file_name'] as String? ?? 'ACCESS media';

    setState(() => _sharing = true);
    try {
      final opened = await runFacebookBrowserShare(
        imageUrl: imageUrl,
        message: title,
        onLogged: () => adminApi.logFacebookShareOpened(
          mediaId: mediaId,
          message: title,
          shareUrl: imageUrl,
        ),
      );
      if (mounted) showFacebookShareSnackBar(context, opened: opened);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _upload() async {
    if (_error != null || !await BackendHealth.isReachable()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend offline. Start it with: ${BackendHealth.startCommand}'),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (_requests.isEmpty) await _load();
    if (_requests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No approved documentation request found. Approve a request under Documentation first.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final picked = await pickImagesFromWeb();
    if (picked.isEmpty) return;
    final requestId = _requests.first['request_id'] as int;

    setState(() => _uploading = true);
    try {
      for (final f in picked) {
        await adminApi.uploadMedia(
          bytes: f.bytes,
          fileName: f.name,
          requestId: requestId,
          displayName: f.name,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${picked.length} file(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.contentBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Browse, upload, and share event photos. Tap an image to enlarge.',
                        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _uploading ? null : _upload,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.accentTeal),
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text('Upload Photo'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: (_sharing || _loading) ? null : _shareToFacebook,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.facebookBlue),
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.facebook, size: 18),
                  label: const Text('Share to Facebook'),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 24),
            AdminUploadZone(onTap: _uploading ? () {} : _upload),
            const SizedBox(height: 22),
            AdminPillTabs(
              labels: _filters,
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 22),
            if (!_loading && _error == null && _requests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Uploads linked to: ${_requests.first['event_name'] ?? _requests.first['title'] ?? 'approved request'}',
                  style: const TextStyle(
                    color: AdminTheme.accentTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No media yet. Upload photos using the zone above.',
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 1100
                      ? 5
                      : constraints.maxWidth > 800
                          ? 4
                          : constraints.maxWidth > 500
                              ? 3
                              : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _AlbumCard(item: _filtered[i], index: i),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.item, required this.index});
  final Map<String, dynamic> item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final url = AdminApiService.mediaUrl(item['file_url'] as String?);
    final isVideo = item['file_type'] == 'video';
    final title = item['file_name'] as String? ?? 'Untitled';
    final uploader = item['uploader_name'] as String? ?? '';
    final gradient = AdminTheme.albumGradientAt(index);

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: url.isNotEmpty && !isVideo ? () => _openViewer(context, url, title) : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty && !isVideo)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(decoration: BoxDecoration(gradient: gradient)),
              )
            else
              Container(decoration: BoxDecoration(gradient: gradient)),
            if (isVideo)
              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                    if (uploader.isNotEmpty)
                      Text(uploader, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.75,
                  maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                ),
                child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
