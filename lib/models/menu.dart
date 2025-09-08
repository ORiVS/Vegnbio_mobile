import 'package:flutter/foundation.dart';
import 'dish.dart';

enum CourseType { entree, plat, dessert, boisson, unknown }

CourseType courseFromStr(String s) {
  switch (s.toUpperCase()) {
    case 'ENTREE': return CourseType.entree;
    case 'PLAT': return CourseType.plat;
    case 'DESSERT': return CourseType.dessert;
    case 'BOISSON': return CourseType.boisson;
    default: return CourseType.unknown;
  }
}

@immutable
class MenuItem {
  final int id;
  final CourseType course;
  final int? dishId;
  final Dish? dish; // si le backend renvoie l’objet

  const MenuItem({required this.id, required this.course, this.dishId, this.dish});

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    final rawDish = j['dish'];
    Dish? dishObj;
    int? dishId;

    if (rawDish is Map<String, dynamic>) {
      dishObj = Dish.fromJson(rawDish);
      dishId = dishObj.id;
    } else if (rawDish is num) {
      dishId = rawDish.toInt();
    }

    return MenuItem(
      id: (j['id'] as num).toInt(),
      course: courseFromStr(j['course_type']?.toString() ?? ''),
      dishId: dishId,
      dish: dishObj,
    );
  }
}

@immutable
class Menu {
  final int id;
  final String title;
  final String? description;
  final String startDate; // YYYY-MM-DD
  final String endDate;   // YYYY-MM-DD
  final List<int> restaurants;
  final bool isPublished;
  final List<MenuItem> items;

  const Menu({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.restaurants,
    required this.isPublished,
    required this.items,
  });

  factory Menu.fromJson(Map<String, dynamic> j) => Menu(
    id: (j['id'] as num).toInt(),
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    startDate: j['start_date']?.toString() ?? '',
    endDate: j['end_date']?.toString() ?? '',
    restaurants: (j['restaurants'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList(),
    isPublished: j['is_published'] == true,
    items: (j['items'] as List<dynamic>? ?? [])
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
