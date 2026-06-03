import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/user_feedback_message.dart';
import 'api_client.dart';

class CognitoUserInfo {
  final String userId;
  final String email;
  final String name;
  final List<String> roles;
  final String facilityId;
  final String? linkedResidentId;
  final String? facilityName;

  CognitoUserInfo({
    required this.userId,
    required this.email,
    required this.name,
    required this.roles,
    required this.facilityId,
    this.linkedResidentId,
    this.facilityName,
  });

  factory CognitoUserInfo.fromJwtPayload(Map<String, dynamic> payload) {
    final groups = payload['cognito:groups'];
    final customRole = payload['custom:role'];
    final roles = <String>[];
    if (groups is List) roles.addAll(groups.map((e) => e.toString()));
    if (customRole is String && customRole.isNotEmpty) roles.add(customRole);

    return CognitoUserInfo(
      userId: (payload['sub'] ?? '').toString(),
      email: (payload['email'] ?? '').toString(),
      name: (payload['name'] ?? payload['email'] ?? '').toString(),
      roles: roles,
      facilityId: (payload['custom:facilityId'] ?? '').toString(),
      linkedResidentId: _optionalString(payload['custom:linkedResidentId']),
      facilityName: _optionalString(payload['custom:facilityName']),
    );
  }

  factory CognitoUserInfo.fromBackendUser(Map<String, dynamic> user,
      {Map<String, dynamic>? fallbackPayload}) {
    final roles = <String>[
      ..._rolesFrom(user['roles']),
      ..._rolesFrom(user['role']),
    ];
    if (roles.isEmpty && fallbackPayload != null) {
      roles.addAll(_rolesFrom(fallbackPayload['cognito:groups']));
      roles.addAll(_rolesFrom(fallbackPayload['custom:role']));
    }

    return CognitoUserInfo(
      userId: (user['userId'] ??
              user['user_id'] ??
              user['sub'] ??
              user['cognitoSub'] ??
              user['cognito_sub'] ??
              fallbackPayload?['sub'] ??
              '')
          .toString(),
      email: (user['email'] ?? fallbackPayload?['email'] ?? '').toString(),
      name: (user['name'] ??
              fallbackPayload?['name'] ??
              user['email'] ??
              fallbackPayload?['email'] ??
              '')
          .toString(),
      roles: roles,
      facilityId: (user['facilityId'] ??
              user['facility_id'] ??
              fallbackPayload?['custom:facilityId'] ??
              '')
          .toString(),
      linkedResidentId: _optionalString(user['linkedResidentId'] ??
          user['linked_resident_id'] ??
          fallbackPayload?['custom:linkedResidentId']),
      facilityName: _optionalString(
          user['facilityName'] ?? fallbackPayload?['custom:facilityName']),
    );
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _rolesFrom(Object? value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  // Map Cognito roles to Arabic UI roles used by AppRiverpod
  String get arabicRole {
    final r = roles.isNotEmpty ? roles.first.toLowerCase() : '';
    switch (r) {
      case 'admin':
        return 'إدارة';
      case 'nurse':
        return 'ممرض';
      case 'doctor':
      case 'clinicalstaff':
      case 'specialist':
        return 'أخصائي اجتماعي';
      case 'family':
        return 'أسرة';
      case 'volunteer':
        return 'متطوع';
      case 'resident':
        return 'مسن';
      default:
        return 'أسرة';
    }
  }
}

class CognitoNewPasswordChallenge {
  final String email;
  final String username;
  final String session;

  const CognitoNewPasswordChallenge({
    required this.email,
    required this.username,
    required this.session,
  });
}

// خدمة المصادقة عبر السيرفر مع الاحتفاظ بتوكنات Cognito للجلسة.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  CognitoUserInfo? _currentUser;
  CognitoUserInfo? get currentUser => _currentUser;

  // تسجيل الدخول → يرجع المستخدم الحالي ويحفظ الـ tokens
  Future<CognitoUserInfo> login(String email, String password) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    final body = _decodeJsonObject(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 401) {
        throw ApiException(401, 'بيانات الدخول غير صحيحة', body);
      }
      throw ApiException(
        res.statusCode,
        _extractErrorMessage(body, fallback: 'فشل تسجيل الدخول'),
        body,
      );
    }

    final idToken = (body['idToken'] ?? '').toString();
    final accessToken =
        (body['accessToken'] ?? body['cognitoAccessToken'] ?? '').toString();
    final sessionToken = idToken.isNotEmpty ? idToken : accessToken;
    final refreshToken = body['refreshToken']?.toString();

    if (sessionToken.isEmpty) {
      throw ApiException(
          500, 'تعذر إكمال تسجيل الدخول حالياً. حاول مرة أخرى.', body);
    }

    await ApiClient.instance.saveTokens(
      idToken: sessionToken,
      refreshToken:
          refreshToken == null || refreshToken.isEmpty ? null : refreshToken,
    );

    final payload = _decodeJwtPayload(sessionToken);
    final backendUser = body['user'];
    _currentUser = backendUser is Map
        ? CognitoUserInfo.fromBackendUser(
            Map<String, dynamic>.from(backendUser),
            fallbackPayload: payload,
          )
        : CognitoUserInfo.fromJwtPayload(payload);

    if (kDebugMode) {
      debugPrint(
          '[Auth] backend login OK → ${_currentUser?.email} roles=${_currentUser?.roles}');
    }

    return _currentUser!;
  }

  Future<CognitoNewPasswordChallenge?> detectNewPasswordChallenge(
    String email,
    String temporaryPassword,
  ) async {
    final cleanEmail = email.trim();
    final body = await _postCognito({
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': ApiConfig.cognitoClientId,
      'AuthParameters': {
        'USERNAME': cleanEmail,
        'PASSWORD': temporaryPassword,
      },
    });

    final challengeName = body['ChallengeName']?.toString();
    if (challengeName != 'NEW_PASSWORD_REQUIRED') return null;

    final params = body['ChallengeParameters'];
    final username = params is Map
        ? (params['USER_ID_FOR_SRP'] ?? params['USERNAME'] ?? cleanEmail)
            .toString()
        : cleanEmail;
    final session = body['Session']?.toString() ?? '';
    if (session.isEmpty) {
      throw ApiException(500, 'تعذر إكمال تفعيل الحساب حالياً. حاول مرة أخرى.');
    }

    return CognitoNewPasswordChallenge(
      email: cleanEmail,
      username: username,
      session: session,
    );
  }

  Future<CognitoUserInfo> completeNewPasswordChallenge({
    required CognitoNewPasswordChallenge challenge,
    required String newPassword,
  }) async {
    final body = await _postCognito({
      'ChallengeName': 'NEW_PASSWORD_REQUIRED',
      'ClientId': ApiConfig.cognitoClientId,
      'Session': challenge.session,
      'ChallengeResponses': {
        'USERNAME': challenge.username,
        'NEW_PASSWORD': newPassword,
      },
    }, target: 'AWSCognitoIdentityProviderService.RespondToAuthChallenge');

    final auth = body['AuthenticationResult'] as Map<String, dynamic>?;
    final idToken = auth?['IdToken']?.toString() ?? '';
    final accessToken = auth?['AccessToken']?.toString() ?? '';
    final refreshToken = auth?['RefreshToken']?.toString();
    final sessionToken = idToken.isNotEmpty ? idToken : accessToken;
    if (sessionToken.isEmpty) {
      throw ApiException(500, 'تعذر إكمال تفعيل الحساب حالياً. حاول مرة أخرى.');
    }

    await ApiClient.instance.saveTokens(
      idToken: sessionToken,
      refreshToken:
          refreshToken == null || refreshToken.isEmpty ? null : refreshToken,
    );

    _currentUser = CognitoUserInfo.fromJwtPayload(
      _decodeJwtPayload(sessionToken),
    );

    if (kDebugMode) {
      debugPrint(
          '[Auth] new password challenge OK → ${_currentUser?.email} roles=${_currentUser?.roles}');
    }

    return _currentUser!;
  }

  // التسجيل الذاتي للأسرة والمتطوع (يستدعي /auth/register في الباك اند)
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'Family' | 'Volunteer'
    required String facilityId,
    String? phone,
    String? linkedResidentId,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'name': name.trim(),
            'role': role,
            'facilityId': facilityId,
            if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
            if (linkedResidentId != null && linkedResidentId.trim().isNotEmpty)
              'linkedResidentId': linkedResidentId.trim(),
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (res.statusCode == 200 || res.statusCode == 201) return;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = body['message'];
    final text =
        msg is List ? msg.join(', ') : msg?.toString() ?? 'فشل التسجيل';
    if (res.statusCode == 409) {
      throw ApiException(409, 'البريد الإلكتروني مستخدم بالفعل');
    }
    throw ApiException(
      res.statusCode,
      friendlyApiErrorMessage(res.statusCode, text, body: body),
      body,
    );
  }

  // تسجيل أول مدير منشأة — لا يحتاج JWT، يحتاج setupSecret
  Future<void> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String facilityId,
    required String setupSecret,
    String? facilityName,
    String? facilityAddress,
    String? licenseNumber,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLocationUrl,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register-admin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'name': name.trim(),
            'facilityId': facilityId.trim(),
            'setupSecret': setupSecret,
            if (facilityName != null && facilityName.trim().isNotEmpty)
              'facilityName': facilityName.trim(),
            if (facilityAddress != null && facilityAddress.trim().isNotEmpty)
              'facilityAddress': facilityAddress.trim(),
            if (licenseNumber != null && licenseNumber.trim().isNotEmpty)
              'licenseNumber': licenseNumber.trim(),
            if (facilityYearOfEst != null &&
                facilityYearOfEst.trim().isNotEmpty)
              'facilityYearOfEst': facilityYearOfEst.trim(),
            if (facilityCapacity != null && facilityCapacity.trim().isNotEmpty)
              'facilityCapacity': facilityCapacity.trim(),
            if (facilityLocationUrl != null &&
                facilityLocationUrl.trim().isNotEmpty)
              'facilityLocationUrl': facilityLocationUrl.trim(),
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (res.statusCode == 200 || res.statusCode == 201) return;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = body['message'];
    final text =
        msg is List ? msg.join(', ') : msg?.toString() ?? 'فشل تسجيل المدير';
    if (res.statusCode == 409) {
      throw ApiException(409, 'البريد الإلكتروني مستخدم بالفعل');
    }
    if (res.statusCode == 401) {
      throw ApiException(401, 'رمز الإعداد غير صحيح');
    }
    throw ApiException(
      res.statusCode,
      friendlyApiErrorMessage(res.statusCode, text, body: body),
      body,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiClient.instance.clearTokens();
  }

  // طلب إرسال كود استعادة كلمة السر إلى البريد الإلكتروني
  Future<void> forgotPassword({required String email}) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 204) {
      return;
    }

    final body = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    final msg = body['message'];
    final text = msg is List
        ? msg.join(', ')
        : msg?.toString() ?? 'تعذر إرسال كود الاستعادة';
    if (res.statusCode == 404) {
      throw ApiException(404, 'لم نعثر على حساب بهذا البريد', body);
    }
    if (res.statusCode == 429) {
      throw ApiException(
          429, 'تم تجاوز الحد المسموح لطلبات الاستعادة، حاول لاحقاً', body);
    }
    throw ApiException(
      res.statusCode,
      friendlyApiErrorMessage(res.statusCode, text, body: body),
      body,
    );
  }

  // تأكيد كود الاستعادة وتعيين كلمة سر جديدة
  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/confirm-forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'code': code.trim(),
            'newPassword': newPassword,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 204) {
      return;
    }

    final body = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    final msg = body['message'];
    final text = msg is List
        ? msg.join(', ')
        : msg?.toString() ?? 'تعذر تعيين كلمة السر الجديدة';
    if (res.statusCode == 400) {
      throw ApiException(400, 'الكود غير صالح أو منتهي الصلاحية', body);
    }
    throw ApiException(
      res.statusCode,
      friendlyApiErrorMessage(res.statusCode, text, body: body),
      body,
    );
  }

  Future<CognitoUserInfo?> refreshSession() async {
    final refreshToken = await ApiClient.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return null;
    }

    final res = await http
        .post(
          Uri.parse(ApiConfig.cognitoEndpoint),
          headers: {
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
            'Content-Type': 'application/x-amz-json-1.1',
          },
          body: jsonEncode({
            'AuthFlow': 'REFRESH_TOKEN_AUTH',
            'ClientId': ApiConfig.cognitoClientId,
            'AuthParameters': {
              'REFRESH_TOKEN': refreshToken,
            },
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      await logout();
      final rawMessage = body['message']?.toString() ?? 'فشل تجديد الجلسة';
      final message = friendlyApiErrorMessage(
        res.statusCode,
        rawMessage,
        body: body,
      );
      throw ApiException(res.statusCode, message, body);
    }

    final auth = body['AuthenticationResult'] as Map<String, dynamic>?;
    final idToken = auth?['IdToken'] as String?;
    if (idToken == null || idToken.isEmpty) {
      await logout();
      throw ApiException(500, 'تعذر تجديد الجلسة. سجّل الدخول مرة أخرى.');
    }

    await ApiClient.instance.saveTokens(
      idToken: idToken,
      refreshToken: refreshToken,
    );

    _currentUser = CognitoUserInfo.fromJwtPayload(_decodeJwtPayload(idToken));

    if (kDebugMode) {
      debugPrint(
          '[Auth] refresh OK → ${_currentUser?.email} roles=${_currentUser?.roles}');
    }

    return _currentUser;
  }

  // التحقق من الجلسة المحفوظة عند فتح التطبيق
  Future<CognitoUserInfo?> restoreSession() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) return null;

    try {
      final payload = _decodeJwtPayload(token);
      final exp = payload['exp'];
      if (exp is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expiry.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
          return refreshSession();
        }
      }
      _currentUser = CognitoUserInfo.fromJwtPayload(payload);
      return _currentUser;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    if (raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'message': decoded.toString()};
  }

  Future<Map<String, dynamic>> _postCognito(
    Map<String, dynamic> payload, {
    String target = 'AWSCognitoIdentityProviderService.InitiateAuth',
  }) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.cognitoEndpoint),
          headers: {
            'X-Amz-Target': target,
            'Content-Type': 'application/x-amz-json-1.1',
          },
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.requestTimeout);

    final body = _decodeJsonObject(res.body);
    if (res.statusCode == 200) return body;

    final type = (body['__type'] ?? '').toString();
    if (type.contains('NotAuthorizedException') ||
        type.contains('UserNotFoundException')) {
      throw ApiException(401, 'بيانات الدخول غير صحيحة', body);
    }
    if (type.contains('InvalidPasswordException')) {
      throw ApiException(
        400,
        'كلمة المرور الجديدة لا تطابق سياسة الأمان المطلوبة',
        body,
      );
    }
    if (type.contains('InvalidParameterException')) {
      throw ApiException(400, 'بيانات تفعيل الحساب غير مكتملة', body);
    }

    throw ApiException(
      res.statusCode,
      _extractErrorMessage(body, fallback: 'تعذر تفعيل الحساب المؤقت'),
      body,
    );
  }

  String _extractErrorMessage(Map<String, dynamic> body,
      {required String fallback}) {
    final msg = body['message'];
    if (msg is List) {
      return msg.map((e) => e.toString()).join(', ');
    }
    final text = msg?.toString();
    return text == null || text.isEmpty ? fallback : text;
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
}
