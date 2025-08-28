import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final VegUser? user;
  final bool loading;
  final String? error;
  const AuthState({required this.isAuthenticated, this.user, this.loading = false, this.error});

  AuthState copyWith({
    bool? isAuthenticated,
    VegUser? user,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    user: user ?? this.user,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

String _dioErr(Object e) {
  if (e is DioException) {
    final r = e.response;
    return 'DioException{type=${e.type}, status=${r?.statusCode}, path=${e.requestOptions.path}, '
        'method=${e.requestOptions.method}, data=${r?.data}}';
  }
  return e.toString();
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false)) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('auth_token');
    print('[AUTH] loadFromStorage access? ${access != null}');
    if (access != null) {
      state = state.copyWith(isAuthenticated: true);
      await fetchMe();
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'CLIENT',
    int? restaurantId,
    Map<String, dynamic>? profile,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    print('[AUTH] register payload role=$role restaurantId=$restaurantId email=$email');
    try {
      final resp = await ApiService.instance.dio.post('/api/accounts/register/', data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        if (restaurantId != null) 'restaurant_id': restaurantId,
        if (profile != null) 'profile': profile,
      });
      print('[AUTH] register status=${resp.statusCode} data=${resp.data}');
      final err = await login(email: email, password: password);
      state = state.copyWith(loading: false);
      return err;
    } catch (e, st) {
      print('[AUTH] register failed: ${_dioErr(e)}');
      print(st);
      state = state.copyWith(loading: false, error: "Inscription impossible");
      return "Inscription impossible";
    }
  }

  Future<String?> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    print('[AUTH] login start email=$email');
    try {
      final res = await ApiService.instance.dio.post('/api/accounts/login/', data: {
        'email': email,
        'password': password,
      });
      print('[AUTH] login status=${res.statusCode} data=${res.data}');

      final access = res.data['access'] as String?;
      final refresh = res.data['refresh'] as String?;
      final prefs = await SharedPreferences.getInstance();
      if (access != null) {
        await prefs.setString('auth_token', access);
        print('[AUTH] stored access token (len=${access.length})');
      }
      if (refresh != null) {
        await prefs.setString('refresh_token', refresh);
        print('[AUTH] stored refresh token (len=${refresh.length})');
      }
      await prefs.setString('auth_email', email);

      state = state.copyWith(isAuthenticated: true, loading: false);
      await fetchMe();
      print('[AUTH] login success -> isAuthenticated=${state.isAuthenticated}');
      return null;
    } catch (e, st) {
      print('[AUTH] login failed: ${_dioErr(e)}');
      print(st);
      state = state.copyWith(loading: false, error: 'Email ou mot de passe invalide');
      return 'Email ou mot de passe invalide';
    }
  }

  Future<void> fetchMe() async {
    print('[AUTH] fetchMe()');
    try {
      final res = await ApiService.instance.dio.get('/api/accounts/me/');
      print('[AUTH] /api/accounts/me/ status=${res.statusCode} data=${res.data}');
      state = state.copyWith(user: VegUser.fromJson(res.data));
    } catch (e, st) {
      print('[AUTH] fetchMe failed: ${_dioErr(e)}');
      print(st);
    }
  }

  Future<void> logout() async {
    print('[AUTH] logout()');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('auth_email');
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
