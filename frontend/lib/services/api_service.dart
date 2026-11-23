import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class ApiService {
  static String get baseUrl {
    return 'https://travelsenseai-wiiy.onrender.com';
  }

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'cached_user_profile';
  static const _onboardingKey = 'onboarding_completed';
  static const _cachedTripsKey = 'cached_trips_data';
  static const _cachedExpensesKey = 'cached_expenses_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    try {
      final data = await _storage.read(key: _userKey);
      if (data != null && data.isNotEmpty) {
        return User.fromJson(jsonDecode(data));
      }
    } catch (_) {
      // In case of any corrupt cached data
    }
    return null;
  }

  static Future<void> saveCachedTrips(String data) async {
    await _storage.write(key: _cachedTripsKey, value: data);
  }

  static Future<String?> getCachedTrips() async {
    return await _storage.read(key: _cachedTripsKey);
  }

  static Future<void> saveCachedExpenses(String data) async {
    await _storage.write(key: _cachedExpensesKey, value: data);
  }

  static Future<String?> getCachedExpenses() async {
    return await _storage.read(key: _cachedExpensesKey);
  }

  static Future<void> saveSession({required String token, required User user}) async {
    await saveToken(token);
    await saveUser(user);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _cachedTripsKey);
    await _storage.delete(key: _cachedExpensesKey);
  }

  static Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  static Future<void> setOnboardingCompleted() async {
    await _storage.write(key: _onboardingKey, value: 'true');
  }

  /// Parses JWT payload without extra external dependencies
  static Map<String, dynamic>? parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if token is expired based on JWT 'exp' claim
  static bool isTokenExpired(String token) {
    try {
      final payload = parseJwt(token);
      if (payload == null) return true;
      if (!payload.containsKey('exp')) return false;

      final exp = payload['exp'];
      if (exp is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        // Add 60 second safety buffer
        return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)));
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Extracts email from JWT 'sub' claim
  static String? getEmailFromToken(String token) {
    final payload = parseJwt(token);
    return payload?['sub']?.toString();
  }

  static Future<http.Response> getRequest(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => http.Response('{"detail":"Connection timeout"}', 408),
        );
  }

  static Future<http.Response> postRequest(String endpoint, Map<String, dynamic> body, {bool isUrlEncoded = false}) async {
    final token = await getToken();
    
    Map<String, String> headers = {};
    if (isUrlEncoded) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    } else {
      headers['Content-Type'] = 'application/json';
    }
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: isUrlEncoded ? body.keys.map((k) => '${Uri.encodeComponent(k)}=${Uri.encodeComponent(body[k].toString())}').join('&') : jsonEncode(body),
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () => http.Response('{"detail":"Connection timeout. The server may be waking up, please try again."}', 408),
    );
  }

  static Future<http.Response> putRequest(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => http.Response('{"detail":"Connection timeout"}', 408),
    );
  }

  static Future<http.Response> deleteRequest(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => http.Response('{"detail":"Connection timeout"}', 408),
    );
  }
}
