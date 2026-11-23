enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  firstTime,
}

class User {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
    };
  }
}

class AuthState {
  final AuthStatus status;
  final bool isLoginLoading;
  final bool isRegisterLoading;
  final String? error;
  final User? user;
  final String? accessToken;

  AuthState({
    this.status = AuthStatus.initial,
    this.isLoginLoading = false,
    this.isRegisterLoading = false,
    this.error,
    this.user,
    this.accessToken,
  });

  bool get isAuthenticated =>
      (status == AuthStatus.authenticated || (user != null && accessToken != null)) &&
      accessToken != null;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoginLoading,
    bool? isRegisterLoading,
    String? error,
    User? user,
    String? accessToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoginLoading: isLoginLoading ?? this.isLoginLoading,
      isRegisterLoading: isRegisterLoading ?? this.isRegisterLoading,
      error: error,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
