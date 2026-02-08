import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// ─── User model ──────────────────────────────────────────

class AppUser {
  final String id;
  final String email;
  final String? name;
  final String subscriptionTier;
  final String language;
  final String selectedAiModel;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.subscriptionTier,
    required this.language,
    required this.selectedAiModel,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      subscriptionTier: (json['subscriptionTier'] as String?) ?? 'free',
      language: (json['language'] as String?) ?? 'tr',
      selectedAiModel: (json['selectedAiModel'] as String?) ?? 'grok',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isPremium => subscriptionTier == 'premium';
}

// ─── Auth state ──────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, AppUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ─── Auth notifier ───────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Check if user has saved tokens and try to restore session
  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasTokens = await ApiClient.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final response = await ApiClient.get('/auth/me');
      final user = AppUser.fromJson(response['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ApiClient.clearTokens();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(status: AuthStatus.error, error: e.message);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await ApiClient.login(email: email, password: password);
      final user = AppUser.fromJson(response['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
    String language = 'tr',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await ApiClient.register(
        email: email,
        password: password,
        name: name,
        language: language,
      );
      final user = AppUser.fromJson(response['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateProfile({String? name, String? language, String? selectedAiModel}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (language != null) body['language'] = language;
      if (selectedAiModel != null) body['selectedAiModel'] = selectedAiModel;

      final response = await ApiClient.patch('/auth/me', body: body);
      final user = AppUser.fromJson(response['user']);
      state = state.copyWith(user: user);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
