import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 预算数据访问。
class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  Stream<List<Budget>> watchAll() => (_db.select(
        _db.budgets,
      )..orderBy([
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
          .watch();

  Future<List<Budget>> getAll() => (_db.select(
        _db.budgets,
      )..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<Budget?> getById(String id) =>
      (_db.select(_db.budgets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insert(BudgetsCompanion entry) =>
      _db.into(_db.budgets).insert(entry);

  Future<void> update(String id, BudgetsCompanion entry) =>
      (_db.update(_db.budgets)..where((t) => t.id.equals(id))).write(entry);

  Future<void> delete(String id) =>
      (_db.delete(_db.budgets)..where((t) => t.id.equals(id))).go();
}
