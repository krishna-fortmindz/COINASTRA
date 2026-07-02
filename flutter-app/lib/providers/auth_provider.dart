import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:ai_trading_copilot/services/pref_keys.dart';
import 'package:ai_trading_copilot/services/shared_pref_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;

  const AuthUser({required this.id, required this.name, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'User',
        email: json['email']?.toString() ?? '',
      );
}

class AuthState {
  final bool isLoggedIn;
  final AuthUser? user;

  const AuthState({this.isLoggedIn = false, this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  void _checkAuth() {
    final token = html.window.localStorage['coinastra_access'];
    if (token == null || token.isEmpty) {
      state = const AuthState(isLoggedIn: false);
      return;
    }
    // Sync Next.js-stored token into SharedPreferences so Flutter's API client can read it
    _syncTokenToPrefs(token);

    AuthUser? user;
    final userJson = html.window.localStorage['coinastra_user'];
    if (userJson != null) {
      try {
        user = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _syncUserIdToPrefs(user);
      } catch (_) {}
    }
    state = AuthState(isLoggedIn: true, user: user);
  }

  void _syncTokenToPrefs(String token) {
    SharedPreferenceService.setValue(PrefKeys.accessToken, token).catchError((_) {});
    final refresh = html.window.localStorage['coinastra_refresh'];
    if (refresh != null && refresh.isNotEmpty) {
      SharedPreferenceService.setValue(PrefKeys.refreshToken, refresh).catchError((_) {});
    }
  }

  void _syncUserIdToPrefs(AuthUser user) {
    if (user.id.isNotEmpty) {
      SharedPreferenceService.setValue(PrefKeys.userId, user.id).catchError((_) {});
    }
  }

  void logout() {
    html.window.localStorage.remove('coinastra_access');
    html.window.localStorage.remove('coinastra_refresh');
    html.window.localStorage.remove('coinastra_user');
    SharedPreferenceService.setValue(PrefKeys.accessToken, '').catchError((_) {});
    SharedPreferenceService.setValue(PrefKeys.refreshToken, '').catchError((_) {});
    state = const AuthState(isLoggedIn: false);
    html.window.location.assign('/auth/login');
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience bool provider — keeps all existing authProvider usages working
final authProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoggedIn;
});
