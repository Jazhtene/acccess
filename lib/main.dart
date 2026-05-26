import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:access_mobile/mobile_app/main_mobile.dart' as mobile;
import 'package:access_mobile/web_admin/main_web.dart' as web_admin;

/// Picks the right entry for the platform:
/// - Chrome / Web → Admin panel ([VisionWebApp])
/// - Android / iOS / desktop → Mobile app ([AccessApp])
void main() {
  if (kIsWeb) {
    web_admin.main();
  } else {
    mobile.main();
  }
}
