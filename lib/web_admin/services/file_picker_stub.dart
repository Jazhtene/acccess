import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Non-web implementation — uses [ImagePicker] on mobile/desktop (no dart:html).
Future<List<({String name, Uint8List bytes})>> pickImagesFromWeb() async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage(imageQuality: 85);
  if (files.isEmpty) return [];
  final results = <({String name, Uint8List bytes})>[];
  for (final file in files) {
    final bytes = await file.readAsBytes();
    results.add((name: file.name, bytes: bytes));
  }
  return results;
}
