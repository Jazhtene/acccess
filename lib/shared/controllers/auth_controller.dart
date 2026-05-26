import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/api/auth_service.dart';
import 'package:access_mobile/shared/controllers/branding_controller.dart';
import 'package:access_mobile/shared/controllers/member_data_controller.dart';
import 'package:access_mobile/shared/models/user_model.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _restoreSession();
  }

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;

  static const _sessionKey = 'access_vision_session';

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _user = AuthUser(
        id: map['id'] as int,
        name: map['name'] as String,
        email: map['email'] as String,
        role: AccessRole.fromApi(map['role'] as String),
        token: map['token'] as String,
      );
      apiClient.setToken(_user!.token);
      if (_user!.role == AccessRole.member || _user!.role == AccessRole.organization) {
        _syncMemberSession();
      }
      notifyListeners();
    } catch (_) {
      await prefs.remove(_sessionKey);
    }
  }

  Future<AuthUser> login(String email, String password) async {
    final user = await authService.login(email, password);
    _user = user;
    await _persist();
    if (user.role == AccessRole.member || user.role == AccessRole.organization) {
      await _syncMemberSession();
    }
    notifyListeners();
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
    await authService.register(
      name: name,
      email: email,
      password: password,
      role: role,
      studentId: studentId,
      contactNumber: contactNumber,
      adviserName: adviserName,
      skillLevel: skillLevel,
    );
  }

  /// Refresh session display name/email after profile edit (keeps token).
  Future<void> updateSessionProfile({String? name, String? email}) async {
    if (_user == null) return;
    _user = AuthUser(
      id: _user!.id,
      name: name ?? _user!.name,
      email: email ?? _user!.email,
      role: _user!.role,
      token: _user!.token,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    authService.logout();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  /// After login, resolve API host then reload branding (logo) from same server as web.
  Future<void> _syncMemberSession() async {
    await memberDataController.refreshAll();
    await brandingController.refresh();
  }

  Future<void> _persist() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode({
      'id': _user!.id,
      'name': _user!.name,
      'email': _user!.email,
      'role': _user!.role.apiValue,
      'token': _user!.token,
    }));
  }
}

final authController = AuthController();
