// lib/core/api_error.dart
import 'package:dio/dio.dart';

class ApiError {
  final int? status;
  final List<String> messages;

  ApiError({this.status, required this.messages});

  @override
  String toString() => messages.join('\n');

  static ApiError fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final msgs = <String>[];

    // Timeouts / réseau
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ApiError(status: null, messages: ["Délai de connexion dépassé."]);
      case DioExceptionType.sendTimeout:
        return ApiError(status: null, messages: ["Délai d’envoi dépassé."]);
      case DioExceptionType.receiveTimeout:
        return ApiError(status: null, messages: ["Délai de réponse dépassé."]);
      case DioExceptionType.badCertificate:
        return ApiError(status: null, messages: ["Certificat SSL invalide."]);
      case DioExceptionType.cancel:
        return ApiError(status: null, messages: ["Requête annulée."]);
      default:
        break;
    }

    // Réponse HTTP avec payload DRF
    if (data != null) {
      msgs.addAll(_extractMessages(data));
    }

    // Fallback par statut
    if (msgs.isEmpty) {
      if (status == 401) msgs.add("Authentification requise.");
      else if (status == 403) msgs.add("Accès interdit.");
      else if (status == 404) msgs.add("Ressource introuvable.");
      else if (status == 409) msgs.add("Conflit. Veuillez réessayer.");
      else if (status != null && status >= 500) msgs.add("Erreur serveur ($status).");
      else msgs.add("Erreur réseau.");
    }

    return ApiError(status: status, messages: msgs);
  }

  static final Map<String, String> _labels = {
    'non_field_errors': '',
    'date': 'Date',
    'start_time': 'Heure de début',
    'end_time': 'Heure de fin',
    'room': 'Salle',
    'restaurant': 'Restaurant',
    'full_restaurant': 'Restaurant entier',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'detail': '',
  };

  static List<String> _extractMessages(dynamic data) {
    final out = <String>[];
    if (data is String) return [data];
    if (data is List) {
      for (final v in data) {
        out.addAll(_extractMessages(v));
      }
      return out;
    }
    if (data is Map) {
      data.forEach((k, v) {
        final label = _labels.containsKey(k) ? _labels[k]! : k.toString();
        final msgs = _extractMessages(v);
        if (label.isEmpty) {
          out.addAll(msgs);
        } else {
          for (final m in msgs) {
            out.add("$label : $m");
          }
        }
      });
      return out;
    }
    return [data.toString()];
  }
}
