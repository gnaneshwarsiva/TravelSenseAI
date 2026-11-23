import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'trip_provider.dart';
import 'expense_provider.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  /// Centralized session check called during app launch / splash
  Future<AuthStatus> checkSession() async {
    try {
      final token = await ApiService.getToken();
      final hasCompletedOnboarding = await ApiService.isOnboardingCompleted();

      // Case 1: No saved session token
      if (token == null || token.trim().isEmpty) {
        final status = hasCompletedOnboarding
            ? AuthStatus.unauthenticated
            : AuthStatus.firstTime;
        state = state.copyWith(status: status, user: null, accessToken: null);
        return status;
      }

      // Case 2: Token exists but is locally expired
      if (ApiService.isTokenExpired(token)) {
        await ApiService.clearSession();
        final status = hasCompletedOnboarding
            ? AuthStatus.unauthenticated
            : AuthStatus.firstTime;
        state = state.copyWith(status: status, user: null, accessToken: null);
        return status;
      }

      // Case 3: Valid unexpired token found! Restore cached user or extract from token
      User? user = await ApiService.getUser();
      if (user == null) {
        final email = ApiService.getEmailFromToken(token) ?? 'user@example.com';
        user = User(
          id: 'user-${email.hashCode.abs()}',
          email: email,
          fullName: email.split('@')[0],
          isActive: true,
        );
        await ApiService.saveUser(user);
      }

      // Ensure onboarding is marked completed since user already has an active session
      if (!hasCompletedOnboarding) {
        await ApiService.setOnboardingCompleted();
      }

      // Restore authenticated state immediately so UI opens smoothly
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: token,
        error: null,
      );

      // Verify with backend in background without logging out on offline/network error
      _verifySessionWithBackend(token);

      return AuthStatus.authenticated;
    } catch (_) {
      // In case of storage read issue, fallback to unauthenticated or firstTime
      final hasCompletedOnboarding = await ApiService.isOnboardingCompleted();
      final status = hasCompletedOnboarding
          ? AuthStatus.unauthenticated
          : AuthStatus.firstTime;
      state = state.copyWith(status: status);
      return status;
    }
  }

  /// Verifies token validity against the backend.
  /// If the server explicitly returns 401 or 403, clear session and log out.
  /// If server is asleep or network is offline, maintain current valid session.
  Future<void> _verifySessionWithBackend(String token) async {
    try {
      final response = await ApiService.getRequest('/trips');
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Backend explicitly rejected the credentials
        await logout();
      }
    } catch (_) {
      // Offline, network timeout, or cold-start: do not wipe valid local credentials!
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoginLoading: true, error: null);

    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      state = state.copyWith(isLoginLoading: false, error: 'Email and password cannot be empty');
      return false;
    }

    try {
      final response = await ApiService.postRequest(
        '/auth/login',
        {
          'username': cleanEmail,
          'password': cleanPassword,
        },
        isUrlEncoded: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        final user = User(
          id: 'user-${cleanEmail.hashCode.abs()}',
          email: cleanEmail,
          fullName: cleanEmail.split('@')[0],
          isActive: true,
        );

        // Save session securely to FlutterSecureStorage
        await ApiService.saveSession(token: token, user: user);
        await ApiService.setOnboardingCompleted();

        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoginLoading: false,
          user: user,
          accessToken: token,
          error: null,
        );
        return true;
      } else {
        String errorMessage = 'Login failed';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('detail')) {
            errorMessage = data['detail'];
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoginLoading: false,
          error: errorMessage,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoginLoading: false,
        error: 'Network error: Please check your connection and try again',
      );
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isRegisterLoading: true, error: null);

    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty || cleanName.isEmpty) {
      state = state.copyWith(isRegisterLoading: false, error: 'All fields are required');
      return false;
    }

    try {
      final response = await ApiService.postRequest(
        '/auth/register',
        {
          'email': cleanEmail,
          'password': cleanPassword,
        },
      );

      if (response.statusCode == 200) {
        await ApiService.setOnboardingCompleted();
        // Auto-login on successful registration
        return await login(cleanEmail, cleanPassword);
      } else {
        String errorMessage = 'Registration failed';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('detail')) {
            errorMessage = data['detail'];
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        state = state.copyWith(isRegisterLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRegisterLoading: false,
        error: 'Network error: Please check your connection and try again',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearSession();
    state = AuthState(status: AuthStatus.unauthenticated);
    // Clear cached trip and expense lists from memory
    ref.invalidate(tripListProvider);
    ref.invalidate(expenseListProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
