import 'package:access_mobile/shared/api/api_client.dart';
import 'package:access_mobile/shared/constants/api_config.dart';

class MemberApiService {
  String mediaUrl(String? path) => ApiConfig.mediaUrl(path);

  String _mediaUrl(String path) => mediaUrl(path);

  Future<Map<String, dynamic>> getProfile() async {
    final data = await apiClient.get('/member/profile');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> getParticipation() async {
    final data = await apiClient.get('/member/participation');
    return Map<String, dynamic>.from(data as Map);
  }

  /// Updates the logged-in user's profile. Returns the updated profile JSON.
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? contactNumber,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email.trim().toLowerCase(),
      if (contactNumber != null) 'contact_number': contactNumber,
      if (newPassword != null && newPassword.isNotEmpty) 'new_password': newPassword,
    };
    final data = await apiClient.patch('/profile', body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> uploadProfileAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final data = await apiClient.postMultipart(
      '/profile/avatar',
      fileBytes: bytes,
      fileName: fileName,
      fields: const {},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final data = await apiClient.get('/tasks');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> updateTaskStatus(int assignmentId, String status) async {
    final data = await apiClient.patch('/tasks/$assignmentId', {'status': status});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final data = await apiClient.get('/events');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await apiClient.get('/notifications');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> markNotificationRead(int id) async {
    await apiClient.patch('/notifications/$id/read', {});
  }

  Future<void> markAllNotificationsRead() async {
    await apiClient.post('/notifications/read-all', {});
  }

  Future<void> clearReadNotifications() async {
    await apiClient.delete('/notifications/read');
  }

  Future<List<Map<String, dynamic>>> getMedia({bool mine = true, String? search}) async {
    final query = <String, String>{if (mine) 'mine': 'true', if (search != null) 'search': search};
    final path = query.isEmpty ? '/media' : '/media?${Uri(queryParameters: query).query}';
    final data = await apiClient.get(path);
    return (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['file_url'] = _mediaUrl(m['file_url'] as String? ?? '');
      return m;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchRepository({String? search, String? fileType}) async {
    final params = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (fileType != null) 'file_type': fileType,
    };
    final path = params.isEmpty
        ? '/repository'
        : '/repository?${Uri(queryParameters: params).query}';
    final data = await apiClient.get(path);
    return (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['file_url'] = _mediaUrl(m['file_url'] as String? ?? '');
      return m;
    }).toList();
  }

  Future<Map<String, dynamic>> uploadMedia({
    required List<int> bytes,
    required String fileName,
    required int requestId,
    String? displayName,
    String? evaluationMetadata,
  }) async {
    final data = await apiClient.postMultipart(
      '/media/upload',
      fileBytes: bytes,
      fileName: fileName,
      fields: {
        'request_id': '$requestId',
        if (displayName != null) 'file_name': displayName,
        if (evaluationMetadata != null) 'evaluation_metadata': evaluationMetadata,
      },
    );
    final m = Map<String, dynamic>.from(data as Map);
    m['file_url'] = _mediaUrl(m['file_url'] as String? ?? '');
    return m;
  }

  Future<List<Map<String, dynamic>>> getEvaluations() async {
    final data = await apiClient.get('/evaluations?mine=true');
    return (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['file_url'] = mediaUrl(m['file_url'] as String?);
      return m;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRankings() async {
    final data = await apiClient.get('/rankings');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> submitFeedback({
    required int requestId,
    required int rating,
    String? comment,
  }) async {
    await apiClient.post('/feedback', {
      'request_id': requestId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getFeedback() async {
    final data = await apiClient.get('/feedback');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> logFacebookShareOpened({
    required int mediaId,
    String? message,
    String? shareUrl,
  }) async {
    await apiClient.post('/facebook/share/opened', {
      'media_id': mediaId,
      if (message != null && message.isNotEmpty) 'message': message,
      if (shareUrl != null && shareUrl.isNotEmpty) 'share_url': shareUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getServiceRequests() async {
    final data = await apiClient.get('/service-requests');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createServiceRequest(Map<String, dynamic> body) async {
    final data = await apiClient.post('/service-requests', body);
    return Map<String, dynamic>.from(data as Map);
  }
}

final memberApiService = MemberApiService();
