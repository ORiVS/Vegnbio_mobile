// lib/providers/auth_me_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';

class AuthMe {
  final int id;
  final String email;
  final String role;
  AuthMe({required this.id, required this.email, required this.role});

  factory AuthMe.fromJson(Map<String, dynamic> j) => AuthMe(
    id: (j['id'] as num).toInt(),
    email: j['email'] ?? '',
    role: j['role'] ?? '',
  );
}

final authMeProvider = FutureProvider<AuthMe>((ref) async {
  final res = await ApiService.instance.dio.get(ApiPaths.me);
  return AuthMe.fromJson(res.data as Map<String, dynamic>);
});
