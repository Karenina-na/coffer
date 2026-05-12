import 'package:drift/drift.dart';

/// 用户自定义的列表地区分组顺序。
///
/// 一个 scene 对应一个展示场景（如 `account_list` / `asset_list`），
/// 每条记录为该场景下某个 region_code 的展示顺序。
@DataClassName('RegionGroupOrderRow')
class RegionGroupOrders extends Table {
  TextColumn get scene => text()();
  TextColumn get regionCode => text().named('region_code')();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(1000))();

  @override
  Set<Column> get primaryKey => {scene, regionCode};
}
