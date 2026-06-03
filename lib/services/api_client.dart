import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/user_feedback_message.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, String message, [this.body])
      : message = friendlyFeedbackMessage(message);
  @override
  String toString() => message;
}

// عميل HTTP موحّد لكل الـ services
// يضيف Bearer token تلقائياً ويعالج أخطاء الشبكة.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_id_token';
  static const _refreshTokenKey = 'jwt_refresh_token';

  String? _cachedToken;

  Future<void> saveTokens(
      {required String idToken, String? refreshToken}) async {
    _cachedToken = idToken;
    await _storage.write(key: _tokenKey, value: idToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, String>> _buildHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final qp = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''))
      ?..removeWhere((_, v) => v.isEmpty);
    return Uri.parse('${ApiConfig.baseUrl}$cleanPath')
        .replace(queryParameters: qp?.isEmpty == true ? null : qp);
  }

  Future<dynamic> get(String path,
      {Map<String, dynamic>? query, bool auth = true}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: await _buildHeaders(auth: auth))
          .timeout(ApiConfig.requestTimeout);
      return _handle(res);
    } on SocketException {
      throw ApiException(0, 'لا يوجد اتصال بالإنترنت — تحقق من الشبكة');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالسيرفر — حاول مرة أخرى');
    }
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    Duration? timeout,
  }) async {
    try {
      final res = await http
          .post(_uri(path),
              headers: await _buildHeaders(auth: auth),
              body: body == null ? null : jsonEncode(body))
          .timeout(timeout ?? ApiConfig.requestTimeout);
      return _handle(res);
    } on SocketException {
      throw ApiException(0, 'لا يوجد اتصال بالإنترنت — تحقق من الشبكة');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالسيرفر — حاول مرة أخرى');
    }
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    try {
      final res = await http
          .patch(_uri(path),
              headers: await _buildHeaders(auth: auth),
              body: body == null ? null : jsonEncode(body))
          .timeout(ApiConfig.requestTimeout);
      return _handle(res);
    } on SocketException {
      throw ApiException(0, 'لا يوجد اتصال بالإنترنت — تحقق من الشبكة');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالسيرفر — حاول مرة أخرى');
    }
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    try {
      final res = await http
          .put(_uri(path),
              headers: await _buildHeaders(auth: auth),
              body: body == null ? null : jsonEncode(body))
          .timeout(ApiConfig.requestTimeout);
      return _handle(res);
    } on SocketException {
      throw ApiException(0, 'لا يوجد اتصال بالإنترنت — تحقق من الشبكة');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالسيرفر — حاول مرة أخرى');
    }
  }

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) async {
    try {
      final res = await http
          .delete(_uri(path),
              headers: await _buildHeaders(auth: auth),
              body: body == null ? null : jsonEncode(body))
          .timeout(ApiConfig.requestTimeout);
      return _handle(res);
    } on SocketException {
      throw ApiException(0, 'لا يوجد اتصال بالإنترنت — تحقق من الشبكة');
    } on TimeoutException {
      throw ApiException(0, 'انتهت مهلة الاتصال بالسيرفر — حاول مرة أخرى');
    }
  }

  dynamic _handle(http.Response res) {
    if (kDebugMode) {
      debugPrint(
          '[API] ${res.request?.method} ${res.request?.url} → ${res.statusCode}');
    }

    final isJson = (res.headers['content-type'] ?? '').contains('json');
    final parsed =
        res.body.isEmpty ? null : (isJson ? jsonDecode(res.body) : res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) return parsed;

    final rawMessage = (parsed is Map && parsed['message'] != null)
        ? parsed['message'].toString()
        : 'HTTP ${res.statusCode}';
    final message = friendlyApiErrorMessage(
      res.statusCode,
      rawMessage,
      body: parsed,
    );
    throw ApiException(res.statusCode, message, parsed);
  }
}
