import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/constants/facebook_config.dart';

class FacebookUserInfo {
  final String userId;
  final String name;
  final String? email;
  final String? pictureUrl;
  final String tokenHint;

  const FacebookUserInfo({
    required this.userId,
    required this.name,
    this.email,
    this.pictureUrl,
    required this.tokenHint,
  });
}

class FacebookAuthService {
  Future<void> _ensureInitialized() async {
    if (!FacebookConfig.isConfiguredAppIdOnly) {
      throw Exception(
        'Facebook App ID not configured.\n\n${FacebookConfig.setupHint()}',
      );
    }

    if (kIsWeb && !FacebookAuth.instance.isWebSdkInitialized) {
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: FacebookConfig.effectiveAppId,
        cookie: true,
        xfbml: false,
        version: 'v19.0',
      );
    }
  }

  Future<FacebookUserInfo?> loginAndConnect() async {
    await _ensureInitialized();

    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success) {
      if (result.status == LoginStatus.cancelled) return null;
      throw Exception(result.message ?? 'Facebook login failed');
    }

    final token = result.accessToken?.tokenString ?? '';
    final userData = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.width(200)',
    );

    final userId = userData['id'] as String? ?? '';
    if (userId.isEmpty) {
      throw Exception('Could not read Facebook user id');
    }

    final name = userData['name'] as String? ?? 'Facebook User';
    final email = userData['email'] as String?;
    final picture = userData['picture'] as Map?;
    final pictureUrl = picture?['data']?['url'] as String?;

    final hint = token.length > 8 ? '…${token.substring(token.length - 8)}' : 'connected';

    await apiClient.post('/facebook/connect', {
      'facebook_user_id': userId,
      'facebook_user_name': name,
      'facebook_email': email,
      'token_hint': hint,
    });

    return FacebookUserInfo(
      userId: userId,
      name: name,
      email: email,
      pictureUrl: pictureUrl,
      tokenHint: hint,
    );
  }

  Future<void> logout() async {
    if (kIsWeb && FacebookAuth.instance.isWebSdkInitialized) {
      await FacebookAuth.instance.logOut();
    } else if (!kIsWeb) {
      await FacebookAuth.instance.logOut();
    }
    try {
      await apiClient.post('/facebook/disconnect', {});
    } catch (_) {}
  }

  Future<bool> isLoggedIn() async {
    if (kIsWeb && !FacebookConfig.isConfiguredAppIdOnly) return false;
    if (kIsWeb && !FacebookAuth.instance.isWebSdkInitialized) {
      final settings = await _fetchDbConnected();
      return settings;
    }
    final token = await FacebookAuth.instance.accessToken;
    return token != null;
  }

  Future<bool> _fetchDbConnected() async {
    try {
      final data = await apiClient.get('/facebook/settings');
      return (data as Map)['is_connected'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> recordShare({
    required int mediaId,
    required String facebookPostId,
  }) async {
    await apiClient.post('/facebook/share', {
      'media_id': mediaId,
      'facebook_post_id': facebookPostId,
    });
  }
}

final facebookAuthService = FacebookAuthService();
