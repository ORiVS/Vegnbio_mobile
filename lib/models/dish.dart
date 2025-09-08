import 'package:flutter/foundation.dart';

@immutable
class AllergenRef {
  final int id;
  final String code;
  final String label;
  const AllergenRef({required this.id, required this.code, required this.label});

  factory AllergenRef.fromJson(Map<String, dynamic> j) => AllergenRef(
    id: (j['id'] as num).toInt(),
    code: j['code']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
  );
}

@immutable
class Dish {
  final int id;
  final String name;
  final String description;
  final double price;
  final bool isVegan;
  final bool isActive;
  final List<AllergenRef> allergens;

  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVegan,
    required this.isActive,
    required this.allergens,
  });

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
    id: (j['id'] as num).toInt(),
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    price: (j['price'] is num) ? (j['price'] as num).toDouble() : double.tryParse('${j['price']}') ?? 0.0,
    isVegan: j['is_vegan'] == true,
    isActive: j['is_active'] != false,
    allergens: (j['allergens'] as List<dynamic>? ?? [])
        .map((e) => AllergenRef.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
