import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../core/constants/category_icons.dart';

/// Immutable domain model for a task category.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    required this.createdAt,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// Stable key resolved through [CategoryIcons].
  final String iconKey;
  final Color color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  IconData get icon => CategoryIcons.resolve(iconKey);

  Category copyWith({
    String? name,
    String? iconKey,
    Color? color,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconKey,
    color,
    isDefault,
    sortOrder,
    createdAt,
  ];
}
