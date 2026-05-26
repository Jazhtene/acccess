import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/member_api_service.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/services/facebook_share_flow.dart';
import 'package:access_mobile/shared/themes/theme.dart';

String _mediaAbsoluteUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${ApiConfig.baseUrl}$path';
}

Future<void> shareGalleryItemToFacebook(BuildContext context, GalleryItem item) async {
  if (item.mediaId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload to server first before sharing to Facebook.')),
    );
    return;
  }

  final imageUrl = _mediaAbsoluteUrl(item.networkUrl);
  if (imageUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No image URL for this item.')),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Share to Facebook'),
      content: Text(
        'Open Facebook to share "${item.title}"?\n\n'
        'You will finish the post in Facebook (no app permissions needed).',
        style: const TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Facebook')),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final opened = await runFacebookBrowserShare(
    imageUrl: imageUrl,
    message: item.title,
    onLogged: () => memberApiService.logFacebookShareOpened(
      mediaId: item.mediaId!,
      message: item.title,
      shareUrl: imageUrl,
    ),
  );

  if (context.mounted) {
    showFacebookShareSnackBar(context, opened: opened);
  }
}
