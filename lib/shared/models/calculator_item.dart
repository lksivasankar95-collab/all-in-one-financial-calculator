import 'package:flutter/material.dart';

class CalculatorItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final String route;
  bool isFavorite;

  CalculatorItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.route,
    this.isFavorite = false,
  });

  CalculatorItem copyWith({bool? isFavorite}) {
    return CalculatorItem(
      id: id,
      name: name,
      description: description,
      category: category,
      icon: icon,
      color: color,
      route: route,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CalculatorCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<CalculatorItem> calculators;

  const CalculatorCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.calculators,
  });
}
