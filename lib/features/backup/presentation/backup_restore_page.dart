import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/error_localizer.dart';
import '../../../domain/usecases/backup_restore.dart';
import '../../auth/presentation/auth_gate.dart';
import 'backup_file_service.dart';
import 'backup_providers.dart';
import 'backup_widgets.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController(text: '');
  PickedBackupPackage? _picked;
  BackupPreview? _preview;
  bool _busy = false;
  String? _status;
  bool _error = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await ref.read(backupFileServiceProvider).pickBackupPackage();
    if (!mounted) return;
    setState(() {
      result.when(
        ok: (picked) {
          _picked = picked;
          _preview = null;
          _status = picked == null ? null : '已选择备份文件：${picked.displayName}';
          _error = false;
        },
        err: (e) {
          _status = '读取备份文件失败：${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  Future<void> _inspect() async {
    final picked = _picked;
    final passwordError = validateBackupPassword(_passwordCtrl.text);
    if (picked == null) {
      setState(() {
        _status = '请先选择备份文件';
        _error = true;
      });
      return;
    }
    if (passwordError != null) {
      setState(() {
        _status = '预检失败：${errorToMessage(passwordError)}';
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _error = false;
    });
    final result = await ref.read(inspectBackupUseCaseProvider).call(
      package: picked.contents,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      result.when(
        ok: (preview) {
          _preview = preview;
          _status = '备份校验通过，可以继续恢复。';
          _error = false;
        },
        err: (e) {
          _preview = null;
          _status = '预检失败：${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  Future<void> _restore() async {
    final picked = _picked;
    final preview = _preview;
    if (picked == null || preview == null) return;
    if (_confirmCtrl.text.trim() != 'RESTORE') {
      setState(() {
        _status = '请先输入 RESTORE 以确认覆盖恢复';
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _error = false;
    });
    final result = await ref.read(importBackupUseCaseProvider).call(
      package: picked.contents,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    result.when(
      ok: (_) {
        GoRouter.of(context).go('/dashboard');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(isUnlockedProvider.notifier).lock();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('恢复完成，已返回首页并重新锁定')),
          );
        });
      },
      err: (e) {
        setState(() {
          _status = '恢复失败：${errorToMessage(e)}';
          _error = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('从备份恢复')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BackupInfoCard(
            icon: Icons.warning_amber_outlined,
            title: '恢复说明',
            description: '恢复会清空并覆盖当前全部业务数据，且不可撤销。',
            trailing: SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          const BackupBulletList(
            items: [
              '请先选择备份文件，再输入口令进行预检。',
              '卡号会恢复并在当前设备上重新加密。',
              'CVV 不会恢复，需重新录入。',
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(_picked == null ? '选择备份文件' : '重新选择备份文件'),
          ),
          if (_picked != null) ...[
            const SizedBox(height: 12),
            Text('文件：${_picked!.displayName}'),
            Text('大小：${_picked!.sizeBytes} 字节'),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: '备份口令'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _inspect,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('验证备份'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 16),
            BackupPreviewCard(
              version: _preview!.version,
              tableCounts: _preview!.tableCounts,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(
                labelText: '输入 RESTORE 确认覆盖恢复',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('覆盖恢复'),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _error ? scheme.errorContainer : scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_status!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
