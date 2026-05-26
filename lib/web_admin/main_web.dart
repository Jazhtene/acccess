import 'package:flutter/material.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/web_admin/app/vision_web_app.dart';

/// Web admin platform — run with:
/// `flutter run -d chrome -t lib/web_admin/main_web.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.runtimeBaseUrl.load();
  await brandingController.refresh();
  runApp(const VisionWebApp());
}
