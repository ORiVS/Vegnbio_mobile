// lib/models/vetbot_models.dart
class VetSpecies {
  final String code;
  final String name;
  VetSpecies({required this.code, required this.name});
  factory VetSpecies.fromJson(Map<String, dynamic> j)
  => VetSpecies(code: j['code'] as String, name: j['name'] as String);
}

class VetBreed {
  final int id;
  final String name;
  VetBreed({required this.id, required this.name});
  factory VetBreed.fromJson(Map<String, dynamic> j)
  => VetBreed(id: j['id'] as int, name: j['name'] as String);
}

class VetSymptom {
  final String code;
  final String label;
  VetSymptom({required this.code, required this.label});
  factory VetSymptom.fromJson(Map<String, dynamic> j)
  => VetSymptom(code: j['code'] as String, label: j['label'] as String);
}

class ParseOutput {
  final String species; // "dog" | "cat" | "unknown"
  final String breed;   // texte libre
  final List<Map<String, dynamic>> symptoms; // [{code, ...}]
  ParseOutput({required this.species, required this.breed, required this.symptoms});
  factory ParseOutput.fromJson(Map<String, dynamic> j) => ParseOutput(
    species: (j['species'] ?? 'unknown') as String,
    breed: (j['breed'] ?? '') as String,
    symptoms: (j['symptoms'] as List).cast<Map<String, dynamic>>(),
  );
}

enum TriageLevel { low, medium, high }
TriageLevel triageFromString(String s) {
  switch (s) {
    case 'high': return TriageLevel.high;
    case 'medium': return TriageLevel.medium;
    default: return TriageLevel.low;
  }
}

class Hypothesis {
  final String disease;
  final double prob; // 0..1
  final String why;  // explications
  Hypothesis({required this.disease, required this.prob, required this.why});
  factory Hypothesis.fromJson(Map<String, dynamic> j) => Hypothesis(
    disease: j['disease'] as String,
    prob: (j['prob'] as num).toDouble(),
    why: (j['why'] ?? '') as String,
  );
}

class TriageOutput {
  final TriageLevel triage;
  final List<Hypothesis> differential;
  final List<String> redFlags;
  final String advice;
  TriageOutput({
    required this.triage,
    required this.differential,
    required this.redFlags,
    required this.advice,
  });

  factory TriageOutput.fromJson(Map<String, dynamic> j) => TriageOutput(
    triage: triageFromString(j['triage'] as String),
    differential: ((j['differential'] ?? []) as List)
        .map((e) => Hypothesis.fromJson(e as Map<String, dynamic>)).toList(),
    redFlags: ((j['red_flags'] ?? []) as List).cast<String>(),
    advice: (j['advice'] ?? '') as String,
  );
}
