import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'nav.dart';
import 'require_auth.dart';
import '../screens/auth/login_screen.dart';

class ApiService {
  ApiService._() {
    debugPrint('[API] Init with baseUrl=$baseUrl');
  }
  static final ApiService instance = ApiService._();

  // ───────────────────────── Base URL ─────────────────────────
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.env['API_BASE_URL'] ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://10.0.2.2:8000';
  }

  static Completer<void>? _refreshCompleter;
  static bool _authDialogOpen = false;

  // Endpoints publics
  static final List<String> _publicPaths = <String>[
    '/api/accounts/login/',
    '/api/accounts/register/',
    '/api/accounts/token/refresh/',
    '/api/restaurants/restaurants/',
    '/api/menu/menus/',
    '/api/menu/dishes/',
    '/api/menu/dish-availability/',
  ];

  bool _isPublicPath(String path) => _publicPaths.any((p) => path.startsWith(p));

  Future<bool> _ensureAuthBeforeRequest(RequestOptions options) async {
    // Public → ok
    if (_isPublicPath(options.path)) return true;

    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('auth_token');
    if (access != null && access.isNotEmpty) return true;

    // Évite d’empiler les modales
    if (_authDialogOpen) return false;
    _authDialogOpen = true;

    try {
      final accepted = await showAuthDialog(
        message: 'Veuillez vous connecter pour continuer.',
      );

      if (accepted) {
        // Pousse la route *après* fermeture de la modale, via le navigator global
        scheduleMicrotask(() {
          final nav = appNavigatorKey.currentState;
          if (nav != null) {
            // Evite d’empiler plusieurs Login
            bool alreadyOnLogin = false;
            nav.popUntil((r) {
              if (r.settings.name == LoginScreen.route) alreadyOnLogin = true;
              return true;
            });
            if (!alreadyOnLogin) nav.pushNamed(LoginScreen.route);
          }
        });
      }
      // on bloque la requête initiale (l’UI relancera après login)
      return false;
    } finally {
      _authDialogOpen = false;
    }
  }

  // ───────────────────────── Dio ─────────────────────────
  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  )
    ..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        // Garde + JWT
        onRequest: (options, handler) async {
          final ok = await _ensureAuthBeforeRequest(options);
          if (!ok) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'auth_required',
              ),
            );
          }

          if (!_isPublicPath(options.path)) {
            final prefs = await SharedPreferences.getInstance();
            final access = prefs.getString('auth_token');
            if (access != null && access.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $access';
            }
          }
          handler.next(options);
        },

        onResponse: (resp, handler) => handler.next(resp),

        // Auto-refresh + invite login si refresh impossible
        onError: (err, handler) async {
          final status = err.response?.statusCode;
          final path = err.requestOptions.path;
          final isAuthPath = path.contains('/api/accounts/login') ||
              path.contains('/api/accounts/token/refresh');

          if (status == 401 && !isAuthPath) {
            final prefs = await SharedPreferences.getInstance();
            final refresh = prefs.getString('refresh_token');

            if (refresh == null || refresh.isEmpty) {
              if (!_authDialogOpen) {
                _authDialogOpen = true;
                try {
                  final accepted = await showAuthDialog(
                    message: 'Votre session a expiré. Veuillez vous reconnecter.',
                  );
                  if (accepted) {
                    scheduleMicrotask(() {
                      appNavigatorKey.currentState?.pushNamed(LoginScreen.route);
                    });
                  }
                } finally {
                  _authDialogOpen = false;
                }
              }
              return handler.next(err);
            }

            // Mutualise le refresh en cours
            if (_refreshCompleter == null) {
              _refreshCompleter = Completer<void>();
              try {
                final resp = await dio.post(
                  '/api/accounts/token/refresh/',
                  data: {'refresh': refresh},
                );
                final newAccess = resp.data['access'] as String?;
                if (newAccess == null || newAccess.isEmpty) {
                  throw DioException(
                    requestOptions: err.requestOptions,
                    error: 'No access token in refresh response',
                  );
                }
                await prefs.setString('auth_token', newAccess);
                _refreshCompleter!.complete();
              } catch (e) {
                _refreshCompleter!.completeError(e);
              }
            }

            try {
              await _refreshCompleter!.future;
            } catch (_) {
              _refreshCompleter = null;
              return handler.next(err);
            }
            _refreshCompleter = null;

            // Retry de la requête originale
            final newAccess =
            (await SharedPreferences.getInstance()).getString('auth_token');
            final req = err.requestOptions;
            final Options opt = Options(
              method: req.method,
              headers: {
                ...req.headers,
                if (newAccess != null) 'Authorization': 'Bearer $newAccess',
              },
              responseType: req.responseType,
              contentType: req.contentType,
            );
            try {
              final response = await dio.request(
                req.path,
                data: req.data,
                queryParameters: req.queryParameters,
                options: opt,
                cancelToken: req.cancelToken,
                onReceiveProgress: req.onReceiveProgress,
                onSendProgress: req.onSendProgress,
              );
              return handler.resolve(response);
            } catch (_) {}
          }

          handler.next(err);
        },
      ),
    );
}
