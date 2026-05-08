import 'package:flutter/material.dart';

class BackupInfoCard extends StatelessWidget {
  const BackupInfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class BackupBulletList extends StatelessWidget {
  const BackupBulletList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class BackupPreviewCard extends StatelessWidget {
  const BackupPreviewCard({super.key, required this.version, required this.tableCounts});

  final int version;
  final Map<String, int> tableCounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('备份预览', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('格式版本：v$version'),
            const SizedBox(height: 8),
            for (final entry in tableCounts.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(_labelOf(entry.key))),
                    Text('${entry.value}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _labelOf(String key) => switch (key) {
        'accounts' => '账户',
        'assets' => '资产',
        'cards' => '卡片',
        'events' => '事件',
        'channels' => '渠道',
        'exchange_rates' => '汇率快照',
        'watched_pairs' => '关注币对',
        _ => key,
      };
}
