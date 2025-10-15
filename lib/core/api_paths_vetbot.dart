// lib/core/api_paths_vetbot.dart
class VetbotApiPaths {
  // Avec base = https://vegnbio.onrender.com/api/vetbot
  static const species  = '/api/v1/vetbot/species/';
  static const breeds   = '/api/v1/vetbot/breeds/';      // + ?species=dog
  static const symptoms = '/api/v1/vetbot/symptoms/';
  static const parse    = '/api/v1/vetbot/parse/';
  static const triage   = '/api/v1/vetbot/triage/';
  static const diseases = '/api/v1/vetbot/diseases/';    // debug interne (non utilisée côté mobile)
  static const feedback = '/api/v1/vetbot/feedback/';    // non utilisée côté mobile
}
