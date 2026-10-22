import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database.dart';
import '../models/category.dart';
import 'mappers.dart';

/// CRUD for categories.
class CategoryRepository {
  CategoryRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Future<List<Category>> getAll() async {
    final rows =
        await (_db.select(_db.categories)..orderBy([
              (c) => OrderingTerm.desc(c.isDefault),
              (c) => OrderingTerm.asc(c.sortOrder),
              (c) => OrderingTerm.asc(c.name),
            ]))
            .get();
    return rows.map(Mappers.categoryFromRow).toList();
  }

  Stream<List<Category>> watchAll() =>
      (_db.select(_db.categories)..orderBy([
            (c) => OrderingTerm.desc(c.isDefault),
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.name),
          ]))
          .watch()
          .map((rows) => rows.map(Mappers.categoryFromRow).toList());

  Future<Category?> getById(String id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : Mappers.categoryFromRow(row);
  }

  Future<void> upsert(Category category) async {
    await _db
        .into(_db.categories)
        .insertOnConflictUpdate(Mappers.categoryToCompanion(category));
  }

  Future<void> reassignTasks(String fromCategoryId, String? toCategoryId) async {
    await (_db.update(_db.tasks)
          ..where((t) => t.categoryId.equals(fromCategoryId)))
        .write(TasksCompanion(categoryId: Value(toCategoryId)));
  }

  Future<void> delete(String id) async {
    // Tasks referencing this category have categoryId set to null by the FK
    // rule, so no data is lost when a category is removed.
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  /// Inserts the default categories, but only if the table is empty. Safe to
  /// call on every launch.
  Future<void> seedDefaultsIfEmpty(List<Category> defaults) async {
    final existing = await _db.select(_db.categories).get();
    if (existing.isNotEmpty) return;
    await _db.batch((b) {
      for (final category in defaults) {
        b.insert(
          _db.categories,
          Mappers.categoryToCompanion(category),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
