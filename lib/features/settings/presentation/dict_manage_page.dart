import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../data/providers/country_data_importer.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/dict_entry.dart';
import '../../../domain/entities/dict_type.dart';

/// 通用字典管理页。传入 [type] 即可复用于转账协议 / 主权地区 / 货币。
///
/// 交互：
/// - 列表按 sortOrder + code 升序；内置条目展示 `已内置` chip、不可删
/// - 右下 FAB 新增条目；条目右侧菜单提供「编辑 / 删除」
/// - 主权地区类型额外展示 flag + continent + 地图坐标列
/// - 主权地区编辑对话框额外暴露 emoji / 大洲 / 颜色 / 经纬度字段
class DictManagePage extends ConsumerStatefulWidget {
  const DictManagePage({super.key, required this.type, required this.title});

  final DictType type;
  final String title;

  @override
  ConsumerState<DictManagePage> createState() => _DictManagePageState();
}

class _DictManagePageState extends ConsumerState<DictManagePage> {
  DictType get type => widget.type;
  String get title => widget.title;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dictEntriesProvider(type));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增条目',
            onPressed: () => _showEditDialog(context, ref, entry: null),
          ),
          if (_isRegion)
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: '从 API 同步国家/地区数据',
              onPressed: () => _syncCountries(context, ref),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (entries) => _buildList(context, ref, entries),
      ),
    );
  }

  bool get _isRegion => type == DictType.sovereigntyRegion;

  Widget _buildRegionSubtitle(DictEntry e) {
    final parts = <Widget>[];
    if (e.continent != null) {
      parts.add(const Icon(Icons.public, size: 12, color: GwpColors.textMuted));
      parts.add(const SizedBox(width: 2));
      parts.add(Text(e.continent!, style: const TextStyle(fontSize: 12)));
    }
    if (e.mapLon != null && e.mapLat != null) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
      parts.add(
        Text(
          '${e.mapLat!.toStringAsFixed(1)}, ${e.mapLon!.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: GwpTypo.monoFont,
            color: GwpColors.textMuted,
          ),
        ),
      );
    }
    if (e.parentRegion != null) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
      parts.add(
        Text(
          '⊂ ${e.parentRegion}',
          style: const TextStyle(fontSize: 11, color: GwpColors.info),
        ),
      );
    }
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(children: parts);
  }

  Future<void> _syncCountries(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('正在从 REST Countries API 同步…'),
          ],
        ),
        duration: Duration(minutes: 5),
      ),
    );
    try {
      final repo = ref.read(dictRepositoryProvider);
      final importer = CountryDataImporter(repo);
      final r = await importer.import();
      messenger.hideCurrentSnackBar();
      r.when(
        ok: (summary) => messenger.showSnackBar(
          SnackBar(
            content: Text(
              '已更新 ${summary.updated} 条，未匹配 ${summary.skippedNoMatch} 条，歧义跳过 ${summary.skippedAmbiguous} 条，代码兜底 ${summary.matchedByCodeFallback} 条，新增币种 ${summary.currencyInserted} 条',
            ),
          ),
        ),
        err: (e) => messenger.showSnackBar(
          SnackBar(content: Text('同步失败：${e.message}')),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('同步异常：$e')));
    }
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<DictEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const Center(child: Text('暂无条目，从右上「更多 → 新建」新增'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: GwpSpacing.sm),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = entries[i];
        return ListTile(
          title: Row(
            children: [
              if (_isRegion && e.flagEmoji != null) ...[
                Text(e.flagEmoji!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: GwpSpacing.sm),
              ],
              Flexible(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: GwpSpacing.sm),
              Text(
                e.code,
                style: const TextStyle(
                  fontFamily: GwpTypo.monoFont,
                  fontSize: 12,
                  color: GwpColors.textMuted,
                ),
              ),
              if (e.isBuiltin) ...[
                const SizedBox(width: GwpSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GwpColors.surface3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '内置',
                    style: TextStyle(fontSize: 10, color: GwpColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
          subtitle: _isRegion
              ? _buildRegionSubtitle(e)
              : e.nameEn == null
              ? null
              : Text(e.nameEn!),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                await _showEditDialog(context, ref, entry: e);
              } else if (v == 'delete') {
                await _confirmDelete(context, ref, e);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              if (!e.isBuiltin)
                const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required DictEntry? entry,
  }) async {
    final result = await showDialog<_DictFormResult>(
      context: context,
      builder: (_) => _DictFormDialog(entry: entry, isRegion: _isRegion),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(dictRepositoryProvider);
    final r = entry == null
        ? await repo.addCustom(
            type: type,
            code: result.code,
            name: result.name,
            nameEn: result.nameEn,
            sortOrder: result.sortOrder,
            flagEmoji: result.flagEmoji,
            continent: result.continent,
            colorHex: result.colorHex,
            mapLon: result.mapLon,
            mapLat: result.mapLat,
            parentRegion: result.parentRegion,
          )
        : await repo.updateEntry(
            id: entry.id,
            name: result.name,
            nameEn: result.nameEn,
            sortOrder: result.sortOrder,
            flagEmoji: result.flagEmoji,
            continent: result.continent,
            colorHex: result.colorHex,
            mapLon: result.mapLon,
            mapLat: result.mapLat,
            parentRegion: result.parentRegion,
          );
    r.when(
      ok: (_) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            entry == null && _isRegion
                ? '已新增，可点击右上角同步补全元数据'
                : (entry == null ? '已新增' : '已更新'),
          ),
        ),
      ),
      err: (e) => messenger.showSnackBar(
        SnackBar(content: Text('操作失败：${errorToMessage(e)}')),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DictEntry e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除条目？'),
        content: Text('将永久删除「${e.name}（${e.code}）」。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GwpColors.negative),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref.read(dictRepositoryProvider).deleteCustom(e.id);
    r.when(
      ok: (_) => messenger.showSnackBar(const SnackBar(content: Text('已删除'))),
      err: (err) => messenger.showSnackBar(
        SnackBar(content: Text('删除失败：${errorToMessage(err)}')),
      ),
    );
  }
}

class _DictFormResult {
  const _DictFormResult({
    required this.code,
    required this.name,
    this.nameEn,
    required this.sortOrder,
    this.flagEmoji,
    this.continent,
    this.colorHex,
    this.mapLon,
    this.mapLat,
    this.parentRegion,
  });
  final String code;
  final String name;
  final String? nameEn;
  final int sortOrder;
  final String? flagEmoji;
  final String? continent;
  final String? colorHex;
  final double? mapLon;
  final double? mapLat;
  final String? parentRegion;
}

class _DictFormDialog extends StatefulWidget {
  const _DictFormDialog({required this.entry, required this.isRegion});
  final DictEntry? entry;
  final bool isRegion;

  @override
  State<_DictFormDialog> createState() => _DictFormDialogState();
}

class _DictFormDialogState extends State<_DictFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _sort;
  late final TextEditingController _flag;
  late final TextEditingController _continent;
  late final TextEditingController _color;
  late final TextEditingController _lon;
  late final TextEditingController _lat;
  late final TextEditingController _parentRegion;
  late bool _showAdvancedRegionMeta;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _code = TextEditingController(text: e?.code ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    _nameEn = TextEditingController(text: e?.nameEn ?? '');
    _sort = TextEditingController(text: (e?.sortOrder ?? 1000).toString());
    _flag = TextEditingController(text: e?.flagEmoji ?? '');
    _continent = TextEditingController(text: e?.continent ?? '');
    _color = TextEditingController(text: e?.colorHex ?? '');
    _lon = TextEditingController(
      text: e?.mapLon != null ? e!.mapLon!.toStringAsFixed(4) : '',
    );
    _lat = TextEditingController(
      text: e?.mapLat != null ? e!.mapLat!.toStringAsFixed(4) : '',
    );
    _parentRegion = TextEditingController(text: e?.parentRegion ?? '');
    _showAdvancedRegionMeta = e != null;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _nameEn.dispose();
    _sort.dispose();
    _flag.dispose();
    _continent.dispose();
    _color.dispose();
    _lon.dispose();
    _lat.dispose();
    _parentRegion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    final codeLocked = editing;

    return AlertDialog(
      title: Text(editing ? '编辑条目' : '新增条目'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 通用字段 ──
              TextFormField(
                controller: _code,
                readOnly: codeLocked,
                decoration: InputDecoration(
                  labelText: '代码',
                  helperText: codeLocked
                      ? '编辑时不允许修改代码'
                      : '大写字母 / 数字 / 下划线，1-32 位',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (codeLocked) return null;
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return '必填';
                  if (!RegExp(r'^[A-Za-z0-9_]{1,32}$').hasMatch(s)) {
                    return '仅限字母 / 数字 / 下划线（1-32）';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: '名称'),
                validator: (v) => (v ?? '').trim().isEmpty ? '必填' : null,
              ),
              TextFormField(
                controller: _nameEn,
                decoration: const InputDecoration(labelText: '英文名（可选）'),
              ),
              TextFormField(
                controller: _sort,
                decoration: const InputDecoration(
                  labelText: '排序',
                  helperText: '数值越小越靠前，默认 1000',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  return int.tryParse(s) == null ? '必须是整数' : null;
                },
              ),

              // ── 地区 UI 元数据（仅主权地区类型展示）──
              if (widget.isRegion) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (!editing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: GwpColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GwpColors.border, width: 0.5),
                    ),
                    child: const Text(
                      '可先只填代码和名称，保存后用右上角同步自动补全旗帜、坐标、大洲和上级区域等信息。',
                      style: TextStyle(
                        fontSize: 12,
                        color: GwpColors.textMuted,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () => setState(() {
                    _showAdvancedRegionMeta = !_showAdvancedRegionMeta;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          editing ? '地区 UI 元数据' : '高级元数据（可选）',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(
                          _showAdvancedRegionMeta
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: GwpColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAdvancedRegionMeta) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _flag,
                    decoration: const InputDecoration(
                      labelText: '国旗 Emoji',
                      helperText: '如 🇨🇳 🇺🇸 🇯🇵',
                    ),
                    maxLength: 4,
                  ),
                  TextFormField(
                    controller: _continent,
                    decoration: const InputDecoration(
                      labelText: '大洲',
                      helperText: '如 亚太 / 欧洲 / 美洲 / 中东',
                    ),
                  ),
                  TextFormField(
                    controller: _color,
                    decoration: const InputDecoration(
                      labelText: '颜色',
                      helperText: '十六进制，如 0xFFEF4444',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lon,
                          decoration: const InputDecoration(
                            labelText: '经度',
                            helperText: '-180 ~ 180',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\-\d.]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lat,
                          decoration: const InputDecoration(
                            labelText: '纬度',
                            helperText: '-90 ~ 90',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\-\d.]')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _parentRegion,
                    decoration: const InputDecoration(
                      labelText: '上级区域',
                      helperText: '如 EU（德国🇩🇪的上级区域为 EU）',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final sortText = _sort.text.trim();
            Navigator.of(context).pop(
              _DictFormResult(
                code: _code.text.trim().toUpperCase(),
                name: _name.text.trim(),
                nameEn: _nameEn.text.trim().isEmpty
                    ? null
                    : _nameEn.text.trim(),
                sortOrder: sortText.isEmpty ? 1000 : int.parse(sortText),
                flagEmoji: _flag.text.trim().isEmpty ? null : _flag.text.trim(),
                continent: _continent.text.trim().isEmpty
                    ? null
                    : _continent.text.trim(),
                colorHex: _color.text.trim().isEmpty
                    ? null
                    : _color.text.trim(),
                mapLon: double.tryParse(_lon.text.trim()),
                mapLat: double.tryParse(_lat.text.trim()),
                parentRegion: _parentRegion.text.trim().isEmpty
                    ? null
                    : _parentRegion.text.trim(),
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
