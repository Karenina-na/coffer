import 'package:drift/drift.dart';

/// 通用字典表。
///
/// 用一张表承载「转账协议 / 主权地区 / 货币」三个业务字典，而不是拆三张表，
/// 因为三者的读写操作完全同构——都是 `列表 / 新增 / 改名 / 停用`。一张表配
/// 一套 DAO / Repository / UI，节省 3× 的模板代码。
///
/// 列含义：
/// - [type]：字典类型标识，取值见 `DictType.code`。查询总是带 `type = ?`
///   过滤，`idx_dict_entries_type_code` UNIQUE 索引兼任主权筛选。
/// - [code]：业务代码，大写 ASCII（SWIFT / CN / USD）。写入前统一大写。
/// - [name]：本地化展示名（当前只存简中；i18n 接入时把列名语义收敛为中文档）。
/// - [nameEn]：可选英文名，列表页搜索时用作命中字段。
/// - [sortOrder]：人工排序，数值越小越靠前。默认 1000 留足内置项之间的空位。
/// - [isBuiltin]：`true` 表示随 App 预置，禁止删除；用户可以改名，但 `code`
///   和 `isBuiltin` 本身不可变。
@DataClassName('DictEntryRow')
class DictEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get nameEn => text().named('name_en').nullable()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(1000))();
  BoolColumn get isBuiltin =>
      boolean().named('is_builtin').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  // ── 地区 UI 元数据（仅 SOVEREIGNTY_REGION 使用，其他类型留空）──────────────
  /// Emoji 国旗，如 `'🇨🇳'`。
  TextColumn get flagEmoji => text().named('flag_emoji').nullable()();
  /// 大洲分组标签，如 `'亚太'` / `'欧洲'` / `'美洲'` / `'中东'`。
  TextColumn get continent => text().nullable()();
  /// 强调色十六进制字符串，如 `'0xFFEF4444'`（与 `Color(0xFFEF4444)` 对应）。
  TextColumn get colorHex => text().named('color_hex').nullable()();
  /// 地理经度（-180 ~ 180），表示国家/地区的真实地理参考位置。
  RealColumn get mapLon => real().named('map_lon').nullable()();
  /// 地理纬度（-90 ~ 90），表示国家/地区的真实地理参考位置。
  RealColumn get mapLat => real().named('map_lat').nullable()();
  /// 地图锚点经度（-180 ~ 180），默认用于金融中心点展示。
  RealColumn get anchorLon => real().named('anchor_lon').nullable()();
  /// 地图锚点纬度（-90 ~ 90），默认用于金融中心点展示。
  RealColumn get anchorLat => real().named('anchor_lat').nullable()();

  /// 所属上级区域 code（如 `DE` 的 `parent_region = 'EU'`）。
  /// 为 `null` 表示顶级区域。UI 展示为「区域 | 国家」层级格式。
  TextColumn get parentRegion => text().named('parent_region').nullable()();
}
