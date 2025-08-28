class MenuItem {
  final String id;
  final String title;
  final String description;
  final List<String> allergens; // ex: ['gluten', 'arachides']
  final double price;
  final int kcal;
  final double rating; // 0..5
  final int prepMinutes; // ex: 45
  final String imageUrl;
  final bool isVegan;

  MenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.allergens,
    required this.price,
    required this.kcal,
    required this.rating,
    required this.prepMinutes,
    required this.imageUrl,
    this.isVegan = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'].toString(),
    title: json['title'] ?? json['name'] ?? '',
    description: json['description'] ?? '',
    allergens: (json['allergens'] as List?)?.map((e) => e.toString()).toList() ?? [],
    price: (json['price'] as num?)?.toDouble() ?? 0,
    kcal: (json['kcal'] as num?)?.toInt() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
    imageUrl: json['image'] ?? json['image_url'] ?? '',
    isVegan: json['is_vegan'] ?? true,
  );
}