import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/models/user_model.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<AuthUser> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    }) as Map<String, dynamic>;

    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(userJson, token);
    _api.setToken(token);
    return user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? contactNumber,
    String? adviserName,
    String? skillLevel,
  }) async {
    await _api.post('/auth/register', {
      'name': name,
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
      if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
      if (adviserName != null && adviserName.isNotEmpty) 'adviser_name': adviserName,
      if (skillLevel != null && skillLevel.isNotEmpty) 'skill_level': skillLevel,
    });
  }

  void logout() => _api.setToken(null);
}

final authService = AuthService(apiClient);
