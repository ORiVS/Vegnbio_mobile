// lib/providers/vetbot_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vetbot_models.dart';
import '../services/vetbot_service.dart';

/// ==== Listes utilitaires ====
final vetSpeciesProvider = FutureProvider<List<VetSpecies>>((ref) async {
  return VetbotService.instance.getSpecies();
});

final vetSymptomsProvider = FutureProvider<List<VetSymptom>>((ref) async {
  return VetbotService.instance.getSymptoms();
});

final vetBreedsProvider = FutureProvider.family<List<VetBreed>, String?>((ref, species) async {
  return VetbotService.instance.getBreeds(species: species);
});

/// ==== Chat items ====
abstract class ChatItem { const ChatItem(); }
class ChatText extends ChatItem {
  final bool fromUser; final String text;
  const ChatText.user(this.text) : fromUser = true;
  const ChatText.bot(this.text)  : fromUser = false;
}
class ChatResult extends ChatItem {
  final TriageOutput result;
  final String? parsedSpecies;
  final List<String> parsedSymptomCodes;
  final bool usedFallbackAdvice; // pour UX conditionnelle
  const ChatResult({
    required this.result,
    required this.parsedSpecies,
    required this.parsedSymptomCodes,
    required this.usedFallbackAdvice,
  });
}

class ChatState {
  final List<ChatItem> items;
  final bool loading;
  final String? error;
  const ChatState({required this.items, this.loading=false, this.error});
  ChatState copy({List<ChatItem>? items, bool? loading, String? error})
  => ChatState(items: items ?? this.items, loading: loading ?? this.loading, error: error);
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(): super(const ChatState(items: [])) {
    _seedWelcome();
  }

  void _seedWelcome() {
    state = state.copy(items: [
      const ChatText.bot("Bonjour et bienvenue sur Vegbot 🐾\nComment puis-je vous aider aujourd’hui ?"),
      const ChatText.bot("Par exemple : « Mon chien vomit », « Mon chat tousse », « Mon chien est apathique »."),
    ]);
  }

  /// Chips de démarrage
  Future<void> quickPrompt(String text) => sendUserText(text);

  /// Enchaînement: user -> parse -> triage -> bot
  Future<void> sendUserText(String text) async {
    if (text.trim().isEmpty) return;
    final items = [...state.items, ChatText.user(text)];
    state = state.copy(items: items, loading: true, error: null);

    try {
      // 1) Parse libre
      final parsed = await VetbotService.instance.parse(text);
      final species = parsed.species; // dog|cat|unknown
      final codes = parsed.symptoms.map((e) => (e['code'] as String)).toList();

      // Fallback minimal si aucune espèce
      final effSpecies = species.isEmpty ? 'unknown' : species;

      // 2) Triage
      final triage = await VetbotService.instance.triage(
        species: effSpecies, breed: parsed.breed, symptoms: codes,
      );

      // 3) Heuristique "IA KO ?" → advice = fallback générique du backend
      final fallbackSignature = "Donnez de l’eau en petites quantités";
      final usedFallback = triage.advice.contains(fallbackSignature);

      state = state.copy(
        items: [...items, ChatResult(
          result: triage,
          parsedSpecies: effSpecies,
          parsedSymptomCodes: codes,
          usedFallbackAdvice: usedFallback,
        )],
        loading: false,
      );
    } catch (e) {
      state = state.copy(
        loading: false,
        error: "Désolé, une erreur est survenue. Veuillez réessayer.",
      );
    }
  }

  void reset() {
    state = const ChatState(items: []);
    _seedWelcome();
  }
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>((ref) => ChatController());
