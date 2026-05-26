import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:access_mobile/shared/constants/api_config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;
  const ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  /// Avoid endless "logging in" spinner when PC backend is off or unreachable.
  static const Duration timeout = Duration(seconds: 15);

  void setToken(String? token) => _token = token;

  String? get token => _token;

  Uri _uriForBase(String baseUrl, String path, [Map<String, String>? query]) {
    final base = '$baseUrl${ApiConfig.apiPrefix}$path';
    return query == null ? Uri.parse(base) : Uri.parse(base).replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String fileName,
    required Map<String, String> fields,
  }) async {
    Object? lastError;
    for (final baseUrl in ApiConfig.candidateBaseUrls()) {
      final uri = _uriForBase(baseUrl, path);
      _log('POST (multipart) $uri  fields=${fields.keys.toList()} file=$fileName (${fileBytes.length} B)');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      try {
        final streamed = await request.send().timeout(timeout);
        final response = await http.Response.fromStream(streamed);
        _log('← ${response.statusCode} POST $uri (${response.body.length} B)');
        final parsed = _parseResponse(response, method: 'POST', uri: uri);
        await _rememberWorkingBaseUrl(baseUrl);
        return parsed;
      } catch (e) {
        lastError = e;
        // Try the next candidate only for connectivity failures.
        final msg = e.toString().toLowerCase();
        final isConnect = msg.contains('socketexception') ||
            msg.contains('connection refused') ||
            msg.contains('failed host lookup') ||
            msg.contains('network is unreachable') ||
            msg.contains('timeout') ||
            msg.contains('timed out');
        if (!isConnect) rethrow;
      }
    }
    // All candidates failed.
    final uri = _uriForBase(ApiConfig.baseUrl, path);
    throw _connectionError(lastError ?? Exception('Connection failed'), method: 'POST', uri: uri);
  }

  Future<void> _rememberWorkingBaseUrl(String baseUrl) async {
    await ApiConfig.saveLastWorkingBaseUrl(baseUrl);
  }

  ApiException _connectionError(Object e, {required String method, required Uri uri}) {
    if (e is ApiException) return e;
    final msg = e.toString().toLowerCase();
    _log('✗ $method $uri  error=$e', isError: true);

    if (msg.contains('timeout') || msg.contains('timed out')) {
      return ApiException(
        'Server timeout at ${ApiConfig.baseUrl}.\n'
        '• On Android emulator the host alias is 10.0.2.2.\n'
        '• On a physical phone, pass --dart-define=API_PUBLIC_HOST=<PC LAN IPv4>.\n'
        '• Start backend: cd access_backend && python manage.py runserver',
      );
    }
    if (msg.contains('failed to fetch') || msg.contains('xmlhttprequest')) {
      return ApiException(
        'Browser blocked the request to ${ApiConfig.baseUrl}. '
        'Ensure backend is running, then stop Flutter and run: '
        'flutter run -d chrome --dart-define-from-file=config/api.json',
      );
    }
    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable')) {
      return ApiException(
        'Cannot reach server at ${ApiConfig.baseUrl}.\n'
        '• Start backend on the PC: cd access_backend && python manage.py runserver\n'
        '• Physical phone? Use the PC LAN IPv4 — pass --dart-define=API_PUBLIC_HOST=192.168.x.x\n'
        '• Android emulator uses 10.0.2.2 (not 127.0.0.1).',
      );
    }
    return ApiException(
      'Cannot reach server at ${ApiConfig.baseUrl}. '
      'Start: cd access_backend && python manage.py runserver',
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    Object? lastError;
    for (final baseUrl in ApiConfig.candidateBaseUrls()) {
      final uri = _uriForBase(baseUrl, path);
      _log('$method $uri${body == null ? '' : '  body=${_truncate(jsonEncode(body))}'}');
      late http.Response response;
      try {
        switch (method) {
          case 'GET':
            response = await _client.get(uri, headers: _headers).timeout(timeout);
            break;
          case 'POST':
            response = await _client
                .post(uri, headers: _headers, body: jsonEncode(body))
                .timeout(timeout);
            break;
          case 'PATCH':
            response = await _client
                .patch(uri, headers: _headers, body: jsonEncode(body))
                .timeout(timeout);
            break;
          case 'DELETE':
            response = await _client.delete(uri, headers: _headers).timeout(timeout);
            break;
          default:
            throw ApiException('Unsupported method $method');
        }
      } catch (e) {
        lastError = e;
        // Only try the next candidate for connectivity-type failures.
        final msg = e.toString().toLowerCase();
        final isConnect = msg.contains('socketexception') ||
            msg.contains('connection refused') ||
            msg.contains('failed host lookup') ||
            msg.contains('network is unreachable') ||
            msg.contains('timeout') ||
            msg.contains('timed out');
        if (!isConnect) {
          throw _connectionError(e, method: method, uri: uri);
        }
        continue;
      }

      _log('← ${response.statusCode} $method $uri (${response.body.length} B)');
      final parsed = _parseResponse(response, method: method, uri: uri);
      await _rememberWorkingBaseUrl(baseUrl);
      return parsed;
    }

    final uri = _uriForBase(ApiConfig.baseUrl, path);
    throw _connectionError(lastError ?? Exception('Connection failed'), method: method, uri: uri);
  }

  dynamic _parseResponse(http.Response response, {required String method, required Uri uri}) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = {'error': response.body.trim()};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? {};
    }

    final map = decoded is Map<String, dynamic> ? decoded : null;
    final detail = map?['detail'];
    final detailMsg = detail is Map<String, dynamic>
        ? (detail['message'] as String? ?? detail['details'] as String?)
        : (detail is String ? detail : null);
    final msg = map?['message'] as String? ??
        detailMsg ??
        map?['error'] as String? ??
        'Request failed (${response.statusCode})';
    _log('✗ $method $uri  status=${response.statusCode}  msg=$msg', isError: true);
    throw ApiException(
      msg,
      statusCode: response.statusCode,
      code: map?['error'] as String? ??
          (detail is Map<String, dynamic> ? detail['code'] as String? : null),
    );
  }

  static String _truncate(String value, [int max = 240]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }

  static void _log(String message, {bool isError = false}) {
    if (!kDebugMode) return;
    developer.log(message, name: 'ACCESS.api', level: isError ? 1000 : 800);
  }
}

final apiClient = ApiClient();
