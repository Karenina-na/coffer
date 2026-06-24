import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/ui/coffer_node_map.dart';
import 'package:coffer/core/ui/region_meta.dart';
import 'package:coffer/features/dashboard/presentation/dashboard_page.dart';
import 'package:coffer/features/wealth/presentation/wealth_trend_provider.dart';

void main() {
  test('dashboard 刷新目标包含今日汇率预警 provider', () {
    expect(dashboardRefreshProviders, contains(todaysRateAlertsProvider));
  });

  // ── heroFilterNodes ─────────────────────────────────────────────────────────

  group('heroFilterNodes', () {
    const cn = MapNode(regionCode: 'CN', label: '¥100', value: 100);
    const us = MapNode(regionCode: 'US', label: '\$200', value: 200);
    const gb = MapNode(regionCode: 'GB', label: '£50', value: 50);
    // XX is not listed in regionIndex
    const xx = MapNode(regionCode: 'XX', label: '?', value: 10);

    final all = [cn, us, gb, xx];

    const regionIndex = <String, RegionMeta>{
      'CN': RegionMeta(code: 'CN', displayName: '中国', continent: '亚太'),
      'US': RegionMeta(code: 'US', displayName: '美国', continent: '美洲'),
      'GB': RegionMeta(code: 'GB', displayName: '英国', continent: '欧洲'),
      'CRYPTO': RegionMeta(code: 'CRYPTO', displayName: '加密', continent: '数字'),
    };

    test('null filter → 所有节点原样返回', () {
      final result = heroFilterNodes(regionIndex, all, null);
      expect(result, same(all));
    });

    test('过滤亚太 → 仅 CN 可见，其余隐藏', () {
      final result = heroFilterNodes(regionIndex, all, {'亚太'});
      expect(result.map((n) => n.regionCode), unorderedEquals(['CN']));
    });

    test('过滤美洲 → 仅 US 可见', () {
      final result = heroFilterNodes(regionIndex, all, {'美洲'});
      expect(result.map((n) => n.regionCode), unorderedEquals(['US']));
    });

    test('过滤多个大洲 → 对应节点全部可见', () {
      final result = heroFilterNodes(regionIndex, all, {'亚太', '欧洲'});
      expect(result.map((n) => n.regionCode), unorderedEquals(['CN', 'GB']));
    });

    test('未知 regionCode (XX) 在过滤激活时被隐藏', () {
      // 回归：旧逻辑 cont==null||vc.contains 会令 XX 泄漏进任何过滤结果
      final result = heroFilterNodes(regionIndex, all, {'亚太'});
      expect(result.any((n) => n.regionCode == 'XX'), isFalse);
    });

    test('未知 regionCode (XX) 在无过滤时正常保留', () {
      final result = heroFilterNodes(regionIndex, all, null);
      expect(result.any((n) => n.regionCode == 'XX'), isTrue);
    });

    test('空节点列表返回空', () {
      expect(heroFilterNodes(regionIndex, [], {'亚太'}), isEmpty);
    });

    test('空 visibleContinents 集合 → 无节点可见', () {
      final result = heroFilterNodes(regionIndex, all, {});
      expect(result, isEmpty);
    });

    test('过滤数字 → 仅 CRYPTO 可见', () {
      const crypto = MapNode(regionCode: 'CRYPTO', label: '₿10', value: 10);
      final result = heroFilterNodes(regionIndex, [cn, crypto], {'数字'});
      expect(result.map((n) => n.regionCode), unorderedEquals(['CRYPTO']));
    });
  });

  // ── heroFilterEdges ─────────────────────────────────────────────────────────

  group('heroFilterEdges', () {
    const cnUs = MapEdge(fromRegion: 'CN', toRegion: 'US');
    const cnHk = MapEdge(fromRegion: 'CN', toRegion: 'HK');
    const usGb = MapEdge(fromRegion: 'US', toRegion: 'GB');

    final all = [cnUs, cnHk, usGb];

    test('仅保留两端都在可见集合中的边', () {
      final result = heroFilterEdges(all, {'CN', 'HK'});
      expect(result, equals([cnHk]));
    });

    test('可见集合包含所有端点 → 全部边保留', () {
      final result = heroFilterEdges(all, {'CN', 'US', 'HK', 'GB'});
      expect(result.length, equals(3));
    });

    test('可见集合为空 → 无边保留', () {
      final result = heroFilterEdges(all, {});
      expect(result, isEmpty);
    });

    test('单端在可见集合中 → 该边被过滤掉', () {
      // CN 在集合中，US 不在 → cnUs 应被过滤
      final result = heroFilterEdges(all, {'CN', 'HK'});
      expect(
        result.any((e) => e.fromRegion == 'US' || e.toRegion == 'US'),
        isFalse,
      );
    });
  });

  group('orderedContinentLabels', () {
    test('标准分组按固定顺序，扩展分组追加在后', () {
      expect(orderedContinentLabels({'数字', '欧洲', '亚太'}), ['亚太', '欧洲', '数字']);
    });
  });
}
