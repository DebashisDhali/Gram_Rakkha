import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gram_rakkha/core/api_client.dart';
import 'package:gram_rakkha/core/entities.dart';

final authRepoProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepoProvider));
});

enum AuthStatus { unknown, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? token;
  final String? error;

  AuthState({required this.status, this.user, this.token, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repo) : super(AuthState(status: AuthStatus.unknown, token: null)) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        // Pass token directly to avoid dependency on storage timing
        final user = await _repo.fetchMe(token: token);
        state = AuthState(status: AuthStatus.authenticated, token: token, user: user);
      } catch (e) {
        // Token expired or invalid — clear and logout
        await _storage.deleteAll();
        state = AuthState(status: AuthStatus.unauthenticated, token: null);
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated, token: null);
    }
  }

  Future<void> login(String phone, String password) async {
    try {
      final data = await _repo.login(phone, password);
      final token = data['access_token'] as String;
      // Save to storage FIRST
      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      // Pass token directly so interceptor doesn't need to read storage
      final user = await _repo.fetchMe(token: token);
      state = AuthState(status: AuthStatus.authenticated, token: token, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString(), token: null);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = AuthState(status: AuthStatus.unauthenticated, token: null);
  }
}

class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _client.post('/auth/login', data: {
      'phone_number': phone,
      'password': password,
    });
    return response.data;
  }

  /// Fetch current user profile. Pass [token] directly to avoid storage timing issues.
  Future<UserEntity> fetchMe({String? token}) async {
    final response = await _client.get('/auth/me', token: token);
    return UserEntity.fromJson(response.data);
  }

  Future<UserEntity> register(
      String name, String phone, String password, double lat, double lng) async {
    final response = await _client.post('/auth/register', data: {
      'full_name': name,
      'phone_number': phone,
      'password': password,
      'home_lat': lat,
      'home_lng': lng,
    });
    return UserEntity.fromJson(response.data);
  }
}
