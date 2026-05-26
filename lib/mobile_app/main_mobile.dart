import 'package:flutter/material.dart';
import 'package:access_mobile/mobile_app/controllers/app.dart';
import 'package:access_mobile/shared/constants/api_config.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';

/// Member / requester mobile app — run on a phone or emulator:
/// `flutter run -t lib/mobile_app/main_mobile.dart`
/// or use the root [main.dart] shortcut.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadLastWorkingBaseUrl();
  // Load branding after we know the last working API host (same DB logo as web admin).
  await brandingController.refresh();
  runApp(const AccessApp());
}
