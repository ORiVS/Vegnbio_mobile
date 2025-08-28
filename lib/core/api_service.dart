import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  ApiService._() {
    // Log clair de la baseUrl effective
    print('[API] Init with baseUrl=$baseUrl');
  }
  static final ApiService instance = ApiService._();

  /// Source de vérité de la base URL :
  /// 1) --dart-define API_BASE_URL
  /// 2) .env (API_BASE_URL=...)
  /// 3) fallback émulateur Android (localhost hôte)
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.env['API_BASE_URL'] ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://10.0.2.2:8000'; // fallback
  }

  static Completer<void>? _refreshCompleter;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl, // ⚠️ sans /api ici (tu mets /api/... dans les chemins).
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'Content-Type': 'application/json'},
    ),
  )
  // Logs verbeux
    ..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    )
  // JWT attach + auto-refresh + retry
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path; // ex: /api/accounts/login/
          // 🔐 Pas de Bearer sur les endpoints auth
          final skipAuth = path.contains('/api/accounts/login') ||
              path.contains('/api/accounts/register') ||
              path.contains('/api/accounts/token/refresh');

          if (!skipAuth) {
            final prefs = await SharedPreferences.getInstance();
            final access = prefs.getString('auth_token');
            if (access != null && access.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $access';
              print('[REQ] ${options.method} ${options.uri}  (Bearer len=${access.length})');
            } else {
              print('[REQ] ${options.method} ${options.uri}  (no Authorization header)');
            }
          } else {
            print('[REQ] ${options.method} ${options.uri}  (auth skipped)');
          }

          if (options.data != null) print('[REQ_BODY] ${options.data}');
          handler.next(options);
        },

        onResponse: (resp, handler) {
          print('[RESP] ${resp.requestOptions.method} ${resp.statusCode} ${resp.requestOptions.path}');
          handler.next(resp);
        },

        onError: (err, handler) async {
          print('[ERR] ${err.requestOptions.method} ${err.requestOptions.uri} '
              'status=${err.response?.statusCode} type=${err.type} data=${err.response?.data}');

          final status = err.response?.statusCode;
          final path = err.requestOptions.path;
          final isAuthPath = path.contains('/api/accounts/login') ||
              path.contains('/api/accounts/token/refresh');

          // 🔁 Refresh access si 401 (et si pas endpoint d'auth)
          if (status == 401 && !isAuthPath) {
            final prefs = await SharedPreferences.getInstance();
            final refresh = prefs.getString('refresh_token');
            print('[REFRESH] Trigger? refresh=${refresh != null}');
            if (refresh == null || refresh.isEmpty) {
              return handler.next(err);
            }

            if (_refreshCompleter == null) {
              _refreshCompleter = Completer<void>();
              try {
                print('[REFRESH] POST /api/accounts/token/refresh/');
                final resp =
                await dio.post('/api/accounts/token/refresh/', data: {'refresh': refresh});
                final newAccess = resp.data['access'] as String?;
                print('[REFRESH] Success? ${newAccess != null}');
                if (newAccess != null && newAccess.isNotEmpty) {
                  await prefs.setString('auth_token', newAccess);
                } else {
                  throw DioException(
                    requestOptions: err.requestOptions,
                    error: 'No access token in refresh response',
                  );
                }
                _refreshCompleter!.complete();
              } catch (e) {
                print('[REFRESH] Failed $e');
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

            // 🔁 Rejoue la requête originale avec le nouveau token
            final newAccess = (await SharedPreferences.getInstance()).getString('auth_token');
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
              print('[RETRY] ${req.method} ${req.uri}');
              final response = await dio.request(
                req.path,
                data: req.data,
                queryParameters: req.queryParameters,
                options: opt,
                cancelToken: req.cancelToken,
                onReceiveProgress: req.onReceiveProgress,
                onSendProgress: req.onSendProgress,
              );
              print('[RETRY_OK] status=${response.statusCode}');
              return handler.resolve(response);
            } catch (e) {
              print('[RETRY_FAIL] $e');
            }
          }

          handler.next(err);
        },
      ),
    );
}
