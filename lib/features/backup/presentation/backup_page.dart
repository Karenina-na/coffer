import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'backup_widgets.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份与恢复')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BackupInfoCard(
            icon: Icons.shield_outlined,
            title: '手动加密备份',
            description: '导出为加密备份文件，用于迁移设备或灾难恢复；这不是多设备实时同步。',
            trailing: SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          BackupInfoCard(
            icon: Icons.upload_file_outlined,
            title: '导出加密备份',
            description: '设置备份口令，生成文件后通过系统分享或保存到安全位置。',
            onTap: () => context.push('/backup/export'),
          ),
          const SizedBox(height: 12),
          BackupInfoCard(
            icon: Icons.restore_page_outlined,
            title: '从备份恢复',
            description: '选择备份文件、输入口令并预检后，覆盖恢复当前全部业务数据。',
            onTap: () => context.push('/backup/restore'),
          ),
          const SizedBox(height: 16),
          const BackupBulletList(
            items: [
              '卡号会计入备份，并在恢复时使用当前设备密钥重新加密。',
              'CVV 不计入备份，恢复后需要重新录入。',
              '恢复会覆盖当前全部业务表，且不可撤销。',
            ],
          ),
        ],
      ),
    );
  }
}
