import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, {this.code});

  bool get isUnauthorized => statusCode == 401;
  bool get isTokenExpired => code == 'TOKEN_EXPIRED';
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // Change this to your production URL when deploying
  // Local testing: use Mac's IP. Production: change to your server URL.
  static const String _baseUrl = 'http://192.168.1.4:3000/api';

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ─── Token management ────────────────────────────────

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<bool> hasTokens() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── Token refresh ───────────────────────────────────

  static Future<bool> _refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (_) {}

    await clearTokens();
    return false;
  }

  // ─── HTTP methods ────────────────────────────────────

  static Map<String, String> _headers(String? token) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      response.statusCode,
      body['error'] ?? 'Unknown error',
      code: body['code'],
    );
  }

  /// Makes an authenticated request with automatic token refresh
  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool authenticated = true,
  }) async {
    String? token;
    if (authenticated) {
      token = await getAccessToken();
      if (token == null) {
        throw ApiException(401, 'Not authenticated');
      }
    }

    Uri uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response response;
    try {
      response = await _makeRequest(method, uri, _headers(token), body);
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }

    // Auto-refresh on 401 TOKEN_EXPIRED
    if (response.statusCode == 401 && authenticated) {
      final data = jsonDecode(response.body);
      if (data['code'] == 'TOKEN_EXPIRED') {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          token = await getAccessToken();
          response = await _makeRequest(method, uri, _headers(token), body);
        } else {
          throw ApiException(401, 'Session expired', code: 'SESSION_EXPIRED');
        }
      }
    }

    return _handleResponse(response);
  }

  static Future<http.Response> _makeRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PATCH':
        return await http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unknown method: $method');
    }
  }

  // ─── Public API ──────────────────────────────────────

  static Future<Map<String, dynamic>> get(String path, {
    Map<String, String>? queryParams,
    bool authenticated = true,
  }) => _request('GET', path, queryParams: queryParams, authenticated: authenticated);

  static Future<Map<String, dynamic>> post(String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _request('POST', path, body: body, authenticated: authenticated);

  static Future<Map<String, dynamic>> put(String path, {
    Map<String, dynamic>? body,
  }) => _request('PUT', path, body: body);

  static Future<Map<String, dynamic>> patch(String path, {
    Map<String, dynamic>? body,
  }) => _request('PATCH', path, body: body);

  static Future<Map<String, dynamic>> delete(String path) =>
      _request('DELETE', path);

  // ─── Auth endpoints (no token needed) ────────────────

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String language = 'tr',
  }) async {
    final response = await post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'language': language,
      },
      authenticated: false,
    );

    await saveTokens(
      accessToken: response['accessToken'],
      refreshToken: response['refreshToken'],
    );

    return response;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

    await saveTokens(
      accessToken: response['accessToken'],
      refreshToken: response['refreshToken'],
    );

    return response;
  }

  static Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    try {
      await post('/auth/logout', body: {'refreshToken': refreshToken ?? ''}, authenticated: false);
    } catch (_) {}
    await clearTokens();
  }
}
