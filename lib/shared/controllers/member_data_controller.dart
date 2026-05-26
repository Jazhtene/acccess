import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/member_api_service.dart';
import 'package:access_mobile/shared/controllers/app_state.dart';
import 'package:access_mobile/shared/controllers/auth_controller.dart';
import 'package:access_mobile/shared/themes/theme.dart';

class MemberDataController extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  int? defaultRequestId;

  Future<void> refreshAll() async {
    if (!authController.isLoggedIn) return;
    isLoading = true;
    error = null;
    appState.isSyncingMemberData = true;
    appState.memberSyncError = null;
    notifyListeners();
    appState.notifyListeners();

    var profileOk = false;
    final warnings = <String>[];

    Future<void> section(String label, Future<void> Function() fn) async {
      try {
        await fn();
      } catch (e) {
        warnings.add('$label: $e');
      }
    }

    await section('Profile', () async {
      final profile = await memberApiService.getProfile();
      final imagePath = profile['profile_image'] as String?;
      appState.applyProfile(
        name: profile['name'] as String? ?? authController.user!.name,
        email: profile['email'] as String? ?? authController.user!.email,
        uploads: profile['uploads_count'] as int? ?? 0,
        skillLevel: profile['skill_level'] as String?,
        points: profile['total_points'] as int? ?? 0,
        rankPosition: profile['rank_position'] as int?,
        contactNumber: profile['contact_number'] as String?,
        studentId: profile['student_id'] as String?,
        profileImage: imagePath != null ? memberApiService.mediaUrl(imagePath) : null,
        role: profile['role'] as String?,
        status: profile['status'] as String?,
      );
      profileOk = true;
    });

    await section('Tasks', () async {
      final tasks = await memberApiService.getTasks();
      if (tasks.isNotEmpty) {
        defaultRequestId = tasks.first['request_id'] as int?;
      }
      appState.challenges
        ..clear()
        ..addAll(tasks.map((t) {
          final status = (t['status'] as String? ?? 'assigned').toLowerCase();
          return Challenge(
            assignmentId: t['id'] as int?,
            requestId: t['request_id'] as int?,
            title: t['request_title'] as String? ?? 'Task',
            description: '${t['task_role'] ?? 'member'} · ${t['venue'] ?? 'TBA'}',
            xp: 150,
            completed: status == 'completed' || status == 'done',
            status: status,
          );
        }));
    });

    await section('Events', () async {
      final events = await memberApiService.getEvents();
      appState.events
        ..clear()
        ..addAll(events.map((e) {
          final start = DateTime.tryParse(e['start_date'] as String? ?? '') ?? DateTime.now();
          final status = _eventStatus(e);
          return CalendarEvent(
            tag: 'COVERAGE',
            title: e['title'] as String? ?? 'Event',
            date: _formatDateTime(start),
            status: status.label,
            statusColor: status.color,
            description: e['venue'] as String? ?? '',
          );
        }));
    });

    await section('Notifications', () async {
      final notifications = await memberApiService.getNotifications();
      appState.notifications
        ..clear()
        ..addAll(notifications.map((n) => AppNotification(
              title: n['title'] as String? ?? '',
              body: n['message'] as String? ?? '',
              icon: Icons.notifications_outlined,
              color: (n['is_read'] as bool? ?? false) ? kTextSecondary : kCyan,
              read: n['is_read'] as bool? ?? false,
            )));
    });

    await section('Gallery', () async {
      final media = await memberApiService.getMedia(mine: true);
      appState.gallery
        ..clear()
        ..addAll(media.map(_galleryFromApi));
    });

    await section('Evaluations', () async {
      final evaluations = await memberApiService.getEvaluations();
      appState.evaluations
        ..clear()
        ..addAll(evaluations.map((e) => Evaluation(
              id: 'MED-${e['media_id']}',
              title: e['file_name'] as String? ?? 'Upload',
              score: (e['overall_score'] as num?)?.toDouble() ?? 0,
              composition: _scoreLabel(e['contrast_score']),
              lighting: _scoreLabel(e['brightness_score']),
              feedback: e['feedback'] as String? ?? '',
              date: _formatIso(e['evaluated_at'] as String?),
              imageUrl: e['file_url'] as String?,
            )));
    });

    await section('Rankings', () async {
      final rankings = await memberApiService.getRankings();
      appState.members
        ..clear()
        ..addAll(rankings.map((r) {
          final name = r['name'] as String? ?? '';
          final parts = name.split(' ');
          final initials = parts.length >= 2
              ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
              : name.isNotEmpty
                  ? name[0].toUpperCase()
                  : '?';
          return Member(
            name: name,
            rank: r['skill_level'] as String? ?? 'Member',
            initials: initials,
            uploads: r['uploads'] as int? ?? 0,
            goodEvaluations: r['good_evaluations'] as int? ?? 0,
            avatarColor: _colorForName(name),
          );
        }));
    });

    await section('Feedback', () async {
      final feedbacks = await memberApiService.getFeedback();
      appState.feedbacks
        ..clear()
        ..addAll(feedbacks.map((f) => EventFeedback(
              eventTitle: 'Request #${f['request_id']}',
              type: 'Service rating',
              message: f['comment'] as String? ?? '',
              rating: f['rating'] as int? ?? 5,
              date: _formatIso(f['created_at'] as String?),
            )));
    });

    await section('Service requests', () async {
      final rows = await memberApiService.getServiceRequests();
      appState.setServiceRequests(rows.map(_serviceRequestFromApi).toList());
    });

    if (!profileOk &&
        appState.evaluations.isEmpty &&
        appState.gallery.isEmpty &&
        appState.challenges.isEmpty) {
      error = warnings.isNotEmpty ? warnings.first : 'Unable to load data from server';
      appState.memberSyncError = error;
    } else {
      error = null;
      appState.memberSyncError = null;
    }

    isLoading = false;
    appState.isSyncingMemberData = false;
    notifyListeners();
    appState.notifyListeners();
  }

  Future<void> createServiceRequest({
    required String title,
    required String description,
    required DateTime eventDate,
    String? venue,
  }) async {
    await memberApiService.createServiceRequest({
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String().split('T').first,
      if (venue != null && venue.isNotEmpty) 'venue': venue,
    });
    await refreshAll();
  }

  ServiceRequest _serviceRequestFromApi(Map<String, dynamic> r) {
    final statusRaw = (r['status'] as String? ?? 'pending').toLowerCase();
    final status = switch (statusRaw) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'in_review' || 'in review' => 'In Review',
      _ => 'Pending',
    };
    final eventDate = DateTime.tryParse(r['event_date'] as String? ?? '') ?? DateTime.now();
    return ServiceRequest(
      id: 'REQ-${r['id']}',
      type: r['title'] as String? ?? 'Request',
      details: r['description'] as String? ?? '',
      date: _formatDate(eventDate),
      requesterName: authController.user?.name ?? 'You',
      status: status,
      requestId: r['id'] as int?,
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> completeTask(int assignmentId) async {
    await memberApiService.updateTaskStatus(assignmentId, 'completed');
    await refreshAll();
  }

  Future<void> uploadMedia({
    required List<int> bytes,
    required String fileName,
    required int requestId,
    String? title,
    String? evaluationMetadata,
  }) async {
    await memberApiService.uploadMedia(
      bytes: bytes,
      fileName: fileName,
      requestId: requestId,
      displayName: title,
      evaluationMetadata: evaluationMetadata,
    );
    await refreshAll();
  }

  Future<void> submitFeedback({
    required int requestId,
    required int rating,
    String? comment,
  }) async {
    await memberApiService.submitFeedback(
      requestId: requestId,
      rating: rating,
      comment: comment,
    );
    await refreshAll();
  }

  Future<void> markAllNotificationsRead() async {
    await memberApiService.markAllNotificationsRead();
    await refreshAll();
  }

  GalleryItem _galleryFromApi(Map<String, dynamic> m) {
    final type = m['file_type'] as String? ?? 'photo';
    final isVideo = type == 'video';
    return GalleryItem(
      title: m['file_name'] as String? ?? 'Media',
      category: 'Coverage',
      date: _formatIso(m['uploaded_at'] as String?),
      color: isVideo ? kPurple : kCyan,
      networkUrl: m['file_url'] as String?,
      mediaType: isVideo ? MediaType.video : MediaType.photo,
      aiDetected: m['ai_detected'] as bool? ?? false,
      mediaId: m['id'] as int?,
      requestId: m['request_id'] as int?,
    );
  }

  ({String label, Color color}) _eventStatus(Map<String, dynamic> e) {
    return (label: 'SCHEDULED', color: kCyan);
  }

  String _scoreLabel(dynamic v) {
    final s = (v as num?)?.toDouble() ?? 0;
    if (s >= 0.8) return 'Excellent';
    if (s >= 0.6) return 'Good';
    return 'Average';
  }

  String _formatIso(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return _formatDateTime(dt);
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$min';
  }

  Color _colorForName(String name) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF06B6D4),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

final memberDataController = MemberDataController();
