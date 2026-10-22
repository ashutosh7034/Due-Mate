import 'package:flutter/material.dart';

/// Maps a stored, stable key to an [IconData].
///
/// Storing icon *keys* rather than raw code points is required for Flutter's
/// icon tree-shaking to work in release builds. Add new entries here (and in
/// the picker) rather than storing arbitrary code points.
class CategoryIcons {
  const CategoryIcons._();

  static const Map<String, IconData> _icons = {
    'folder': Icons.folder_outlined,
    'school': Icons.school_outlined,
    'work': Icons.work_outline_rounded,
    'code': Icons.code_rounded,
    'person': Icons.person_outline_rounded,
    'groups': Icons.groups_outlined,
    'payments': Icons.payments_outlined,
    'event': Icons.event_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'home': Icons.home_outlined,
    'fitness': Icons.fitness_center_rounded,
    'book': Icons.menu_book_outlined,
    'flight': Icons.flight_takeoff_rounded,
    'health': Icons.favorite_border_rounded,
    'build': Icons.build_outlined,
    'star': Icons.star_border_rounded,
  };

  static const String defaultKey = 'folder';

  static IconData resolve(String? key) =>
      _icons[key ?? defaultKey] ?? Icons.folder_outlined;

  /// Keys offered in the category editor.
  static List<String> get keys => _icons.keys.toList(growable: false);

  static Map<String, IconData> get all => Map.unmodifiable(_icons);
}
