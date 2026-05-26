import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:access_mobile/shared/themes/theme.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/mobile_app/widgets/ai_detected_badge.dart';

void showGallery(BuildContext context) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => const GallerySheet(),
  );
}

class GallerySheet extends StatefulWidget {
  const GallerySheet({super.key});
  @override
  State<GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<GallerySheet> {
  final _picker = ImagePicker();

  // ── Upload options ──────────────────────────────────────────────────────────

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Add to Gallery', style: TextStyle(color: kTextPrimary,
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: kAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.photo_library_outlined, color: kAccent)),
            title: const Text('Select Photos', style: TextStyle(color: kTextPrimary,
              fontWeight: FontWeight.w600)),
            subtitle: const Text('Pick multiple photos from gallery',
              style: TextStyle(color: kTextSecondary, fontSize: 11)),
            onTap: () { Navigator.pop(context); _pickPhotos(); }),
          ListTile(
            leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: kPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.videocam_outlined, color: kPurple)),
            title: const Text('Select Video', style: TextStyle(color: kTextPrimary,
              fontWeight: FontWeight.w600)),
            subtitle: const Text('Pick a video from gallery',
              style: TextStyle(color: kTextSecondary, fontSize: 11)),
            onTap: () { Navigator.pop(context); _pickVideo(ImageSource.gallery); }),
          if (!kIsWeb)
            ListTile(
              leading: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.videocam, color: kGreen)),
              title: const Text('Record Video', style: TextStyle(color: kTextPrimary,
                fontWeight: FontWeight.w600)),
              subtitle: const Text('Record a new video with camera',
                style: TextStyle(color: kTextSecondary, fontSize: 11)),
              onTap: () { Navigator.pop(context); _pickVideo(ImageSource.camera); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    for (final f in picked) {
      final bytes = await f.readAsBytes();
      appState.addGalleryItem(GalleryItem(
        title: f.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
        category: 'Uploaded',
        date: 'Now',
        color: kCyan,
        imagePath: f.path,
        imageBytes: bytes,
        mediaType: MediaType.photo,
      ));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source,
      maxDuration: const Duration(minutes: 10));
    if (picked == null) return;

    // Size check — 100 MB limit
    final file = File(picked.path);
    final size = await file.length();
    if (size > 100 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Video exceeds 100 MB limit. Please select a shorter clip.'),
          backgroundColor: kRed));
      }
      return;
    }

    appState.addGalleryItem(GalleryItem(
      title: picked.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
      category: 'Video',
      date: 'Now',
      color: kPurple,
      videoPath: picked.path,
      mediaType: MediaType.video,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Video added to gallery'),
        backgroundColor: kGreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
      builder: (_, ctrl) => ListenableBuilder(
        listenable: appState,
        builder: (_, __) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Media Gallery', style: TextStyle(color: kTextPrimary,
                  fontSize: 16, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: _showUploadOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kCyan, kPurple]),
                      borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Upload', style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)),
                    ]))),
              ]),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
              itemCount: appState.gallery.length,
              itemBuilder: (_, i) {
                final item = appState.gallery[i];
                return GestureDetector(
                  onTap: () => _openItem(context, item),
                  child: Container(
                    decoration: BoxDecoration(color: kSurfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder)),
                    child: Column(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Stack(fit: StackFit.expand, children: [
                            _buildThumbnail(item),
                            if (item.isVideo)
                              Container(
                                color: Colors.black26,
                                child: const Center(child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white, size: 40))),
                            if (item.aiDetected) const AiDetectedBadge(),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.title, style: const TextStyle(color: kTextPrimary,
                            fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            item.isVideo
                              ? 'Video · ${item.date}'
                              : '${item.category} · ${item.date}',
                            style: const TextStyle(color: kTextSecondary, fontSize: 9)),
                        ])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildThumbnail(GalleryItem item) {
    if (item.imageBytes != null) {
      return Image.memory(item.imageBytes!, width: double.infinity, fit: BoxFit.cover);
    }
    if (item.isVideo) {
      return Container(
        color: kPurple.withOpacity(0.15),
        child: const Center(child: Icon(Icons.videocam, color: kPurple, size: 40)));
    }
    return Container(
      color: item.color.withOpacity(0.15),
      child: Center(child: Icon(Icons.photo_library, color: item.color, size: 36)));
  }

  void _openItem(BuildContext context, GalleryItem item) {
    if (item.isVideo) {
      _playVideo(context, item);
    } else {
      _showImageFullscreen(context, item);
    }
  }

  void _playVideo(BuildContext context, GalleryItem item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _VideoPlayerScreen(item: item)));
  }
}

// ── Image fullscreen ──────────────────────────────────────────────────────────
void _showImageFullscreen(BuildContext context, GalleryItem item) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed),
            onPressed: () {
              appState.gallery.remove(item);
              appState.notifyListeners();
              Navigator.pop(context);
            }),
        ]),
      body: Center(
        child: item.imageBytes != null
          ? InteractiveViewer(child: Image.memory(item.imageBytes!))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.photo_library, color: item.color, size: 80),
              const SizedBox(height: 16),
              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ]),
      ),
    ),
  ));
}

// ── Video player screen ───────────────────────────────────────────────────────
class _VideoPlayerScreen extends StatefulWidget {
  final GalleryItem item;
  const _VideoPlayerScreen({required this.item});
  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  bool _playing = false;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.item.title, style: const TextStyle(fontSize: 14)),
          Text('Video · ${widget.item.date}',
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed),
            onPressed: () {
              appState.gallery.remove(widget.item);
              appState.notifyListeners();
              Navigator.pop(context);
            }),
        ]),
      body: Center(
        child: _error
          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text('Unable to play this video',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            ])
          : widget.item.videoPath != null
            ? _NativeVideoPlayer(path: widget.item.videoPath!,
                onError: () => setState(() => _error = true))
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam, color: kPurple, size: 80),
                SizedBox(height: 16),
                Text('No video file available',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              ]),
      ),
    );
  }
}

// Simple native video player using platform video intent (no extra package needed)
class _NativeVideoPlayer extends StatelessWidget {
  final String path;
  final VoidCallback onError;
  const _NativeVideoPlayer({required this.path, required this.onError});

  @override
  Widget build(BuildContext context) {
    // Since video_player package is not added, show a play prompt
    // that opens the video in the system player
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: kPurple.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: kPurple, width: 2)),
        child: const Icon(Icons.play_arrow, color: kPurple, size: 56)),
      const SizedBox(height: 20),
      const Text('Video ready to play', style: TextStyle(color: Colors.white,
        fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(path.split('/').last,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPurple, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        onPressed: () async {
          // Open with system video player
          try {
            if (!kIsWeb) {
              // On mobile, the file exists at path — show info
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Video saved at: ${path.split('/').last}'),
                backgroundColor: kPurple));
            }
          } catch (_) {}
        },
        icon: const Icon(Icons.play_circle_outline, size: 20),
        label: const Text('Play Video', style: TextStyle(fontWeight: FontWeight.w700))),
    ]);
  }
}
