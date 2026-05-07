import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/network/network_providers.dart';

enum AuthStatus { authenticated, unauthenticated, initial }

class AuthState {
  final AuthStatus status;
  final String? token;

  AuthState({required this.status, this.token});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated(String token) => AuthState(status: AuthStatus.authenticated, token: token);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorage _storage;

  AuthNotifier(this._storage) : super(AuthState.initial()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.getSessionToken();
    if (token != null && token.isNotEmpty) {
      state = AuthState.authenticated(token);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String token) async {
    await _storage.saveSessionToken(token);
    state = AuthState.authenticated(token);
  }

  Future<void> logout() async {
    await _storage.deleteSessionToken();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});
