import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/error_localizer.dart';
import '../../../domain/usecases/backup_restore.dart';
import 'backup_providers.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final _pwdCtrl = TextEditingController();
  final _pkgCtrl = TextEditingController();
  bool _busy = false;
  String? _status;
  bool _error = false;
  Timer? _clipboardClearTimer;

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    _pwdCtrl.dispose();
    _pkgCtrl.dispose();
    super.dispose();
  }

  String? _passwordErrorText() {
    final error = validateBackupPassword(_pwdCtrl.text);
    return error == null ? null : errorToMessage(error);
  }

  Future<void> _export() async {
    final passwordError = _passwordErrorText();
    if (passwordError != null) {
      setState(() {
        _status = '导出失败: $passwordError';
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _error = false;
    });
    final r = await ref
        .read(exportBackupUseCaseProvider)
        .call(password: _pwdCtrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      r.when(
        ok: (pkg) {
          _pkgCtrl.text = pkg;
          _status = '导出完成，长度 ${pkg.length}。可复制 / 另存';
          _error = false;
        },
        err: (e) {
          _status = '导出失败: ${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  Future<void> _import() async {
    final passwordError = _passwordErrorText();
    if (passwordError != null) {
      setState(() {
        _status = '导入失败: $passwordError';
        _error = true;
      });
      return;
    }
    if (_pkgCtrl.text.isEmpty) {
      setState(() {
        _status = '请填写备份内容';
        _error = true;
      });
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('覆盖本地数据？'),
        content: const Text('导入将清空并覆盖当前所有业务表，操作不可回退。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _status = null;
      _error = false;
    });
    final r = await ref
        .read(importBackupUseCaseProvider)
        .call(package: _pkgCtrl.text, password: _pwdCtrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      r.when(
        ok: (_) {
          _status = '导入成功';
          _error = false;
        },
        err: (e) {
          _status = '导入失败: ${errorToMessage(e)}';
          _error = true;
        },
      );
    });
  }

  /// 安全复制：提示用户备份密文一旦外泄配合弱口令即可离线爆破，
  /// 确认后写入剪贴板并在 60 秒后自动清空。
  Future<void> _copy() async {
    if (_pkgCtrl.text.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('复制到剪贴板？'),
        content: const Text(
          '剪贴板对其他应用可见。密文一旦被截取，配合弱口令可被离线暴力破解。\n\n'
          '确认后 60 秒内将自动清空剪贴板。建议尽快粘贴到安全位置后再清空。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续复制'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Clipboard.setData(ClipboardData(text: _pkgCtrl.text));
    _scheduleClipboardClear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制 · 60 秒后自动清空')));
  }

  void _scheduleClipboardClear() {
    _clipboardClearTimer?.cancel();
    final expected = _pkgCtrl.text;
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () async {
      final cur = await Clipboard.getData('text/plain');
      // 仅当剪贴板内容仍然是本次复制的备份包时才清空，避免踩掉用户后续的
      // 其它复制内容。
      if (cur?.text == expected) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _pkgCtrl.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('备份 / 恢复')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '口令（Argon2id 派生密钥）',
              helperText: '至少 10 位；建议使用长口令，后续恢复必须一致，遗失无法找回',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('导出加密备份'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('导入覆盖'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pkgCtrl,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: '备份包 JSON',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('复制'),
              ),
              TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.paste_outlined),
                label: const Text('粘贴'),
              ),
            ],
          ),
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
