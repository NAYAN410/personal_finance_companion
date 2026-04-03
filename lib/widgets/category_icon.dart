import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  const CategoryIcon({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'food':
        icon = Icons.restaurant;
        break;
      case 'transport':
        icon = Icons.directions_car;
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        break;
      case 'entertainment':
        icon = Icons.movie;
        break;
      default:
        icon = Icons.category;
    }
    return CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(icon, color: Colors.blue.shade800));
  }
}