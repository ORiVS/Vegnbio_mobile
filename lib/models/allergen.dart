// lib/models/allergen.dart
class Allergen {
  final int id;
  final String code;
  final String label;

  Allergen({required this.id, required this.code, required this.label});

  factory Allergen.fromJson(Map<String, dynamic> j) => Allergen(
    id: (j['id'] as num).toInt(),
    code: j['code'] ?? '',
    label: j['label'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'label': label,
  };
}
