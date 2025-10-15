// lib/core/jwt_decode.dart
import 'dart:convert';

class JwtDecode {
  static Map<String, dynamic>? _decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(payload));
      final map = json.decode(jsonStr);
      return (map is Map<String, dynamic>) ? map : null;
    } catch (_) {
      return null;
    }
  }

  /// Retourne user_id si présent (DRF SimpleJWT)
  static int? userId(String? accessToken) {
    final p = (accessToken == null || accessToken.isEmpty) ? null : _decode(accessToken);
    final v = p?['user_id'];
    if (v is int) return v;
    if (v is String) {
      final n = int.tryParse(v);
      return n;
    }
    return null;
  }
}
