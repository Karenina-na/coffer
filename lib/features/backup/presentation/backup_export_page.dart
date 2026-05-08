import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/error_localizer.dart';
import '../../../domain/usecases/backup_restore.dart';
import 'backup_providers.dart';
import 'backup_widgets.dart';

class BackupExportPage extends ConsumerStatefulWidget {
  const BackupExportPage({super.key});

  @override
  ConsumerState<BackupExportPage> createState() => _BackupExportPageState();
}

class _BackupExportPageState extends ConsumerState<BackupExportPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _package;
  String? _status;
  bool _error = false;
  Timer? _clipboardClearTimer;

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validationMessage() {
    final passwordError = validateBackupPassword(_passwordCtrl.text);
    if (passwordError != null) {
      return errorToMessage(passwordError);
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      return '两次输入的口令不一致';
    }
    return null;
  }

  Future<void> _generate() async {
    final message = _validationMessage();
    if (message != null) {
      setState(() {
        _status = '导出失败：$message';
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _error = false;
    });
    final result = await ref
        .read(exportBackupUseCaseProvider)
        .call(password: _passwordCtrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      result.when(
        ok: (pkg) {
          _package = pkg;
          _status = '已生成加密备份文件，可立即分享或复制文本备份。';
          _error = false;
        },
        err: (e) {
          _status = '导出失败：${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  Future<void> _share() async {
    final package = _package;
    if (package == null) return;
    setState(() => _busy = true);
    final fileResult = await ref.read(backupFileServiceProvider).createBackupFile(package);
    if (!mounted) return;
    if (fileResult.isErr) {
      setState(() {
        _busy = false;
        _status = '生成文件失败：${errorToMessage(fileResult.errorOrNull)}';
        _error = true;
      });
      return;
    }
    final shareResult = await ref.read(backupFileServiceProvider).shareBackupFile(fileResult.valueOrNull!);
    if (!mounted) return;
    setState(() {
      _busy = false;
      shareResult.when(
        ok: (_) {
          _status = '已调起系统分享，请保存到你信任的位置。';
          _error = false;
        },
        err: (e) {
          _status = '分享失败：${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  Future<void> _copyAdvanced() async {
    final package = _package;
    if (package == null) return;
    await Clipboard.setData(ClipboardData(text: package));
    _scheduleClipboardClear(package);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制文本备份 · 60 秒后自动清空剪贴板')),
    );
  }

  void _scheduleClipboardClear(String expected) {
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () async {
      final cur = await Clipboard.getData('text/plain');
      if (cur?.text == expected) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('导出加密备份')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BackupInfoCard(
            icon: Icons.privacy_tip_outlined,
            title: '导出说明',
            description: '备份文件会被口令加密。口令遗失后无法恢复；文件泄露时，弱口令可被离线暴力破解。',
            trailing: SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          const BackupBulletList(
            items: [
              '建议使用长口令，并用密码管理器保存。',
              '卡号会计入备份并在恢复时重新加密。',
              'CVV 不计入备份，恢复后需要重新录入。',
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: '备份口令',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: !_showPassword,
            decoration: const InputDecoration(labelText: '再次输入口令'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.enhanced_encryption_outlined),
            label: const Text('生成加密备份'),
          ),
          if (_package != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.share_outlined),
              label: const Text('分享备份文件'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _copyAdvanced,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('高级方式：复制文本备份'),
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
