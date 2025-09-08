import 'package:flutter/material.dart';

class DishAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl; // si plus tard tu ajoutes un champ image
  const DishAvatar({super.key, required this.name, this.size = 64, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6F3),
        borderRadius: BorderRadius.circular(size),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    );
  }
}
