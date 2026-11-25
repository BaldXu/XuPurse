import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';

/// 账单位置数据访问。
///
/// 位置与账单 1:1（主键 bill_id），删除账单时由外键级联清理；
/// 独立成表是为了后续「消费地图」能直接按城市/区县聚合。
class BillLocationRepository {
  BillLocationRepository(this._db);

  final AppDatabase _db;

  Future<BillLocation?> getByBillId(String billId) =>
      (_db.select(_db.billLocations)
            ..where((t) => t.billId.equals(billId)))
          .getSingleOrNull();

  /// 写入/覆盖某笔账单的位置。
  Future<void> save({
    required String billId,
    double? lat,
    double? lng,
    String coordSystem = 'wgs84',
    double? accuracy,
    String? name,
    String? address,
    String? province,
    String? city,
    String? district,
    String? adcode,
    String? poiId,
    String source = 'manual',
    int? capturedAt,
  }) async {
    await _db
        .into(_db.billLocations)
        .insertOnConflictUpdate(
          BillLocationsCompanion.insert(
            billId: billId,
            lat: Value(lat),
            lng: Value(lng),
            coordSystem: Value(coordSystem),
            accuracy: Value(accuracy),
            name: Value(name),
            address: Value(address),
            province: Value(province),
            city: Value(city),
            district: Value(district),
            adcode: Value(adcode),
            poiId: Value(poiId),
            source: Value(source),
            capturedAt:
                capturedAt ?? DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> delete(String billId) =>
      (_db.delete(_db.billLocations)..where((t) => t.billId.equals(billId)))
          .go();
}
