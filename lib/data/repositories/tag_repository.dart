import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 标签数据访问。
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  Stream<List<Tag>> watchAll() =>
      (_db.select(_db.tags)..orderBy([
            (t) => OrderingTerm.asc(t.sort),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
          .watch();

  Future<List<Tag>> getAll() =>
      (_db.select(_db.tags)..orderBy([
            (t) => OrderingTerm.asc(t.sort),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
          .get();

  Future<Tag?> getById(String id) =>
      (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tag?> findByName(String name) => (_db.select(
    _db.tags,
  )..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<void> insert(TagsCompanion entry) => _db.into(_db.tags).insert(entry);

  Future<void> update(String id, TagsCompanion entry) =>
      (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(entry);

  Future<void> delete(String id) =>
      (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
}
