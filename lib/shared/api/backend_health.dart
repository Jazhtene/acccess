import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/constants/api_config.dart';

/// Quick reachability check for FastAPI (`GET /api/health`).
class BackendHealth {
  static Future<bool> isReachable() async {
    try {
      final data = await apiClient.get('/health');
      if (data is Map && data['status'] == 'ok') return true;
      return data != null;
    } catch (_) {
      return false;
    }
  }

  static String get startCommand =>
      'cd access_backend && python manage.py runserver';

  static String get healthUrl => '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/health';
}
