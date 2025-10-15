// lib/services/vetbot_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/api_paths_vetbot.dart';
import '../models/vetbot_models.dart';

class VetbotService {
  VetbotService._() {
    print('[VETBOT] Init baseUrl=$baseUrl');
  }
  static final VetbotService instance = VetbotService._();

  static String get baseUrl {
    const dd = String.fromEnvironment('VETBOT_BASE_URL', defaultValue: '');
    if (dd.isNotEmpty) return dd;
    final env = dotenv.env['VETBOT_BASE_URL'] ?? '';
    if (env.isNotEmpty) return env;
    // fallback public (prod)
    return 'https://vegnbio.onrender.com/api/vetbot';
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(LogInterceptor(
      request: true, requestHeader: true, requestBody: true,
      responseBody: true, responseHeader: false, error: true,
      logPrint: (o) => print('[VETBOT] $o')));

  // ===== Lists =====
  Future<List<VetSpecies>> getSpecies() async {
    final r = await _dio.get(VetbotApiPaths.species);
    final list = (r.data as List).map((e)=>VetSpecies.fromJson(e)).toList();
    return list;
  }

  Future<List<VetBreed>> getBreeds({String? species}) async {
    final r = await _dio.get(
      VetbotApiPaths.breeds,
      queryParameters: { if (species != null && species.isNotEmpty) 'species': species },
    );
    return (r.data as List).map((e)=>VetBreed.fromJson(e)).toList();
  }

  Future<List<VetSymptom>> getSymptoms() async {
    final r = await _dio.get(VetbotApiPaths.symptoms);
    return (r.data as List).map((e)=>VetSymptom.fromJson(e)).toList();
  }

  // ===== NLP parse =====
  Future<ParseOutput> parse(String text) async {
    final r = await _dio.post(VetbotApiPaths.parse, data: {'text': text});
    return ParseOutput.fromJson(r.data as Map<String, dynamic>);
  }

  // ===== Triage =====
  Future<TriageOutput> triage({
    required String species,
    String? breed,
    required List<String> symptoms,
  }) async {
    final body = {
      'species': species,
      'breed': (breed ?? ''),
      'symptoms': symptoms,
    };
    final r = await _dio.post(VetbotApiPaths.triage, data: body);
    return TriageOutput.fromJson(r.data as Map<String, dynamic>);
  }
}
