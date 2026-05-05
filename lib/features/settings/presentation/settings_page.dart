import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../mock_seeder.dart';
import '../../../domain/entities/dict_type.dart';
import '../../../domain/usecases/reset_all_data.dart';
import '../../account/presentation/account_providers.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../backup/presentation/backup_providers.dart';
import 'dict_manage_page.dart';
import 'security_settings_page.dart';

/// 「重置所有数据」用例的 provider。
///
/// 放在设置页旁边而非独立 providers 文件，是因为这个 UseCase 只有一个消费方，
/// 再拆一层只会增加阅读成本。
final resetAllDataUseCaseProvider = Provider<ResetAllDataUseCase>((ref) {
  return ResetAllDataUseCase(
    snapshot: ref.watch(dbSnapshotRepositoryProvider),
    pinStore: ref.watch(pinStoreProvider),
  );
});

@visibleForTesting
bool shouldShowDebugTools({bool debugMode = kDebugMode}) => debugMode;

/// 立即锁屏：
/// 1) 先用 GoRouter 把位置复位到 `/dashboard``，避免解锁后停留在 `/settings`
///    这类壳路由之外的页面；
/// 2) 等路由切换提交到下一帧后再翻 `isUnlockedProvider` 为 false，确保不会在
///    `context.go` 之前把当前页从树上拆掉，导致返回首页锁定后再次输入 PIN 报错。
void _lockNow(BuildContext context, WidgetRef ref) {
  final router = GoRouter.of(context);
  router.go('/dashboard');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(isUnlockedProvider.notifier).lock();
  });
}

/// 打开某个字典类型的管理页。独立函数方便多个入口复用。
void _openDict(
  BuildContext context, {
  required DictType type,
  required String title,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => DictManagePage(type: type, title: title),
    ),
  );
}

/// 设置页。只聚合 **App 级全局设置**（备份、关于等）。
///
/// 功能局部的配置（如「通道管理」属于转账功能）应放在各功能内部的二级 Tab，
/// 不进入这里。这样避免设置页成为所有功能的杂货铺。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemaVersion = ref.watch(databaseSchemaVersionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.base,
          vertical: GwpSpacing.md,
        ),
        children: [
          _SectionCard(
            icon: Icons.storage_outlined,
            iconColor: GwpColors.actionPrimary,
            title: '数据',
            children: [
              _EntryRow(
                icon: Icons.backup_outlined,
                title: '备份与恢复',
                onTap: () => context.push('/backup'),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          _SectionCard(
            icon: Icons.lock_outline,
            iconColor: GwpColors.info,
            title: '安全',
            children: [
              _EntryRow(
                icon: Icons.pin_outlined,
                title: 'PIN 与指纹',
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const SecuritySettingsPage(),
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  return _EntryRow(
                    icon: Icons.logout_outlined,
                    title: '立即锁定',
                    onTap: () => _lockNow(context, ref),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          _SectionCard(
            icon: Icons.menu_book_outlined,
            iconColor: GwpColors.actionPrimary,
            title: '字典',
            children: [
              _EntryRow(
                icon: Icons.swap_horiz_outlined,
                title: '转账协议',
                onTap: () => _openDict(
                  context,
                  type: DictType.transferProtocol,
                  title: '转账协议字典',
                ),
              ),
              _EntryRow(
                icon: Icons.public_outlined,
                title: '国家 / 地区',
                onTap: () => _openDict(
                  context,
                  type: DictType.sovereigntyRegion,
                  title: '国家 / 地区字典',
                ),
              ),
              _EntryRow(
                icon: Icons.currency_exchange_outlined,
                title: '货币',
                onTap: () =>
                    _openDict(context, type: DictType.currency, title: '货币字典'),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          _SectionCard(
            icon: Icons.warning_amber_rounded,
            iconColor: GwpColors.negative,
            title: '危险区',
            children: [
              Consumer(
                builder: (context, ref, _) {
                  return _EntryRow(
                    icon: Icons.delete_forever_outlined,
                    title: '清除所有数据',
                    onTap: () => _resetAllData(context, ref),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          _SectionCard(
            icon: Icons.info_outline,
            iconColor: GwpColors.info,
            title: '关于',
            children: [
              _EntryRow(
                icon: Icons.apps_outlined,
                title: '应用名称',
                trailing: const Text(
                  'Coffer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textSecondary,
                  ),
                ),
              ),
              _EntryRow(
                icon: Icons.info_outline,
                title: '应用版本',
                // 与 pubspec.yaml 的 `version:` 字段保持同步；发布新版本时需一起改。
                trailing: const Text(
                  'v0.1.0 (1)',
                  style: TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textSecondary,
                  ),
                ),
              ),
              _EntryRow(
                icon: Icons.storage_outlined,
                title: '数据库 Schema',
                trailing: Text(
                  'v$schemaVersion',
                  style: const TextStyle(
                    fontFamily: GwpTypo.monoFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textSecondary,
                  ),
                ),
              ),
              _EntryRow(
                icon: Icons.shield_outlined,
                title: '数据存储',
              ),
              _EntryRow(
                icon: Icons.article_outlined,
                title: '开源许可',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Coffer',
                  applicationVersion: 'v0.1.0',
                ),
              ),
            ],
          ),
          const SizedBox(height: GwpSpacing.md),
          const _ApiDiagSection(),
          if (kDebugMode) ...[
            const SizedBox(height: GwpSpacing.md),
            _SectionCard(
              icon: Icons.science_outlined,
              iconColor: GwpColors.warning,
              title: 'DEBUG',
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    return _EntryRow(
                      icon: Icons.auto_awesome_motion_outlined,
                      title: '一次性注入测试数据',
                      onTap: () => _seedMockData(context, ref),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _seedMockData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: GwpColors.warning,
        size: 32,
      ),
      title: const Text('注入测试数据？'),
      content: const Text(
        '此操作会向当前数据库插入一批演示账户 / 资产 / 卡片 / 通道 / '
        '事件与 30 日价格历史。\n\n'
        '• 与真实写入路径一致\n'
        '• 写入后无法一键撤销\n\n'
        '确定继续吗？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: GwpColors.warning),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('注入'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // Show persistent snackbar while working.
  messenger.clearSnackBars();
  messenger.showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text('正在注入测试数据…'),
        ],
      ),
      duration: Duration(minutes: 5),
    ),
  );

  try {
    final result = await seedMockData(ref);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (result.skipped) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('已检测到历史数据'),
          content: const Text('库中已有资产。仅在你清楚当前是测试库时选择"强制注入"。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GwpColors.warning),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('强制注入'),
            ),
          ],
        ),
      );
      if (retry != true) return;
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('正在强制注入…'),
            ],
          ),
          duration: Duration(minutes: 5),
        ),
      );
      final forced = await seedMockData(ref, force: true);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('强制注入完成\n$forced'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('示例数据已录入\n$result'),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('注入失败: ${errorToMessage(e)}'),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

/// 「清除所有数据」的完整交互：两步确认 → 执行 → 锁屏 → 反馈。
///
/// 只需输入"清除"一词即可执行；单步确认，避免误触。
Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _ResetConfirmDialog(),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(content: Text('正在清除数据…'), duration: Duration(seconds: 2)),
  );

  final useCase = ref.read(resetAllDataUseCaseProvider);
  final r = await useCase(clearPin: false);
  if (!context.mounted) return;
  messenger.hideCurrentSnackBar();

  r.when(
    ok: (_) {
      _lockNow(context, ref);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('数据已清除'),
          duration: Duration(seconds: 3),
        ),
      );
    },
    err: (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('清除失败: ${errorToMessage(e)}')),
      );
    },
  );
}

class _ResetConfirmDialog extends StatefulWidget {
  const _ResetConfirmDialog();

  @override
  State<_ResetConfirmDialog> createState() => _ResetConfirmDialogState();
}

class _ResetConfirmDialogState extends State<_ResetConfirmDialog> {
  static const _magic = '清除';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text.trim() == _magic;
    return AlertDialog(
      icon: const Icon(
        Icons.delete_forever_outlined,
        color: GwpColors.negative,
        size: 32,
      ),
      title: const Text('清除所有数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('输入"清除"以确认：'),
          const SizedBox(height: GwpSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '清除',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: GwpColors.negative),
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text('清除'),
        ),
      ],
    );
  }
}

// ─── API 诊断区域 ────────────────────────────────────────────────────────────

/// 需要测试的外部 API 端点列表。
///
/// [label]       显示名称
/// [host]        主机名（用于连通性摘要）
/// [testUri]     实际发起 HEAD/GET 的 URL
/// [description] 用途说明
class _ApiEndpoint {
  const _ApiEndpoint({
    required this.label,
    required this.host,
    required this.testUri,
    required this.description,
    this.icon = Icons.cloud_outlined,
  });
  final String label;
  final String host;
  final Uri testUri;
  final String description;
  final IconData icon;
}

final _kApiEndpoints = [
  // ── 股票行情 ──────────────────────────────────────────────
  _ApiEndpoint(
    label: '东方财富行情',
    host: 'push2delay.eastmoney.com',
    testUri: Uri.https('push2delay.eastmoney.com', '/api/qt/stock/get', {
      'secid': '1.600519',
      'fields': 'f43',
      'fltt': '2',
      'invt': '2',
    }),
    description: '沪深港 A 股实时报价（国内直连）',
    icon: Icons.show_chart_outlined,
  ),
  _ApiEndpoint(
    label: '东方财富 K 线',
    host: 'push2his.eastmoney.com',
    testUri: Uri.https(
      'push2his.eastmoney.com',
      '/api/qt/stock/kline/get',
      {
        'secid': '1.600519',
        'fields1': 'f1,f2',
        'fields2': 'f51,f53',
        'klt': '101',
        'fqt': '1',
        'beg': '20250101',
        'end': '20250102',
      },
    ),
    description: '沪深港股历史 K 线（国内直连）',
    icon: Icons.candlestick_chart_outlined,
  ),
  _ApiEndpoint(
    label: 'Yahoo Finance',
    host: 'query1.finance.yahoo.com',
    testUri: Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/AAPL',
      {'interval': '1d', 'range': '1d'},
    ),
    description: '美股 / 港股 / 加密货币备用行情（需境外网络）',
    icon: Icons.language_outlined,
  ),
  // ── 加密货币 ──────────────────────────────────────────────
  _ApiEndpoint(
    label: 'CoinGecko',
    host: 'api.coingecko.com',
    testUri: Uri.https(
      'api.coingecko.com',
      '/api/v3/simple/price',
      {'ids': 'bitcoin,ethereum', 'vs_currencies': 'usd'},
    ),
    description: '加密货币实时报价（BTC/ETH/SOL 等，免认证）',
    icon: Icons.currency_bitcoin_outlined,
  ),
  // ── 法币汇率 ──────────────────────────────────────────────
  _ApiEndpoint(
    label: 'Frankfurter 汇率',
    host: 'api.frankfurter.dev',
    testUri: Uri.https(
      'api.frankfurter.dev',
      '/v1/latest',
      {'base': 'USD', 'symbols': 'CNY,HKD,EUR,GBP,SGD'},
    ),
    description: '法币实时汇率（欧央行数据源，免认证）',
    icon: Icons.currency_exchange_outlined,
  ),
];

enum _TestStatus { idle, testing, ok, error }

class _ApiDiagSection extends StatefulWidget {
  const _ApiDiagSection();

  @override
  State<_ApiDiagSection> createState() => _ApiDiagSectionState();
}

class _ApiDiagSectionState extends State<_ApiDiagSection> {
  final _statuses = List.filled(_kApiEndpoints.length, _TestStatus.idle);
  final _messages = List<String?>.filled(_kApiEndpoints.length, null);
  final _latencies = List<int?>.filled(_kApiEndpoints.length, null);
  bool _testingAll = false;

  Future<void> _test(int i) async {
    if (_statuses[i] == _TestStatus.testing) return;
    setState(() {
      _statuses[i] = _TestStatus.testing;
      _messages[i] = null;
      _latencies[i] = null;
    });
    final ep = _kApiEndpoints[i];
    final sw = Stopwatch()..start();
    try {
      final client = http.Client();
      try {
        final resp = await client
            .get(ep.testUri, headers: const {'User-Agent': 'Coffer/1 (diag)'})
            .timeout(const Duration(seconds: 10));
        sw.stop();
        if (!mounted) return;
        setState(() {
          _latencies[i] = sw.elapsedMilliseconds;
          if (resp.statusCode < 400) {
            _statuses[i] = _TestStatus.ok;
            _messages[i] = 'HTTP ${resp.statusCode}';
          } else {
            _statuses[i] = _TestStatus.error;
            _messages[i] = 'HTTP ${resp.statusCode}';
          }
        });
      } finally {
        client.close();
      }
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _statuses[i] = _TestStatus.error;
        _messages[i] = _shortError(e);
        _latencies[i] = sw.elapsedMilliseconds;
      });
    }
  }

  Future<void> _testAll() async {
    if (_testingAll) return;
    setState(() => _testingAll = true);
    await Future.wait([
      for (var i = 0; i < _kApiEndpoints.length; i++) _test(i),
    ]);
    if (mounted) setState(() => _testingAll = false);
  }

  String _shortError(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) return '超时';
    if (s.contains('SocketException')) return '无法连接';
    if (s.contains('HandshakeException')) return 'TLS 握手失败';
    if (s.length > 40) return '${s.substring(0, 40)}…';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.wifi_tethering_outlined,
      iconColor: GwpColors.info,
      title: '网络连通性',
      children: [
        for (var i = 0; i < _kApiEndpoints.length; i++)
          _ApiTestRow(
            endpoint: _kApiEndpoints[i],
            status: _statuses[i],
            message: _messages[i],
            latency: _latencies[i],
            onTap: () => _test(i),
          ),
        // 「全部测试」按钮行
        InkWell(
          onTap: _testingAll ? null : _testAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GwpSpacing.base,
              vertical: GwpSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_testingAll)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: GwpColors.actionPrimary,
                  ),
                const SizedBox(width: 6),
                Text(
                  _testingAll ? '测试中…' : '全部测试',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.actionPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApiTestRow extends StatelessWidget {
  const _ApiTestRow({
    required this.endpoint,
    required this.status,
    required this.message,
    required this.latency,
    required this.onTap,
  });

  final _ApiEndpoint endpoint;
  final _TestStatus status;
  final String? message;
  final int? latency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: status == _TestStatus.testing ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.base,
          vertical: GwpSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: GwpColors.surface3,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                endpoint.icon,
                size: 16,
                color: GwpColors.textSecondary,
              ),
            ),
            const SizedBox(width: GwpSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GwpColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endpoint.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GwpColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: GwpSpacing.sm),
            _StatusChip(
              status: status,
              message: message,
              latency: latency,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.message,
    required this.latency,
  });

  final _TestStatus status;
  final String? message;
  final int? latency;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _TestStatus.idle:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: GwpColors.surface3,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '点击测试',
            style: TextStyle(fontSize: 11, color: GwpColors.textMuted),
          ),
        );
      case _TestStatus.testing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _TestStatus.ok:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: GwpColors.positive.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            latency != null ? '✓ ${latency}ms' : '✓ 连通',
            style: const TextStyle(fontSize: 11, color: GwpColors.positive),
          ),
        );
      case _TestStatus.error:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: GwpColors.negative.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message != null ? '✗ $message' : '✗ 失败',
            style: const TextStyle(fontSize: 11, color: GwpColors.negative),
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }
}

// ─── Section Card / Entry Row ────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwpColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GwpSpacing.base,
              GwpSpacing.md,
              GwpSpacing.base,
              GwpSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: GwpSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: GwpColors.border),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1,
                indent: GwpSpacing.base + 24 + GwpSpacing.md,
                color: GwpColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GwpSpacing.base,
          vertical: GwpSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: GwpColors.surface3,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: GwpColors.textSecondary),
            ),
            const SizedBox(width: GwpSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GwpColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: GwpColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (onTap != null) ...[
              const SizedBox(width: GwpSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: GwpColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
