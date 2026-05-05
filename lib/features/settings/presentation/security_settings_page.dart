import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/design_tokens.dart';
import '../../auth/presentation/auth_gate.dart';

/// 安全设置：修改 PIN、启用/禁用生物识别快捷解锁。
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _loading = true;
  bool _biometricEnabled = false;
  bool _biometricDeviceReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final pin = ref.read(pinStoreProvider);
    final auth = ref.read(biometricAuthProvider);
    final enabled = await pin.isBiometricEnabled();
    final ready = await auth.canCheckBiometrics();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _biometricDeviceReady = ready;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool v) async {
    final pin = ref.read(pinStoreProvider);
    if (v) {
      // 开启前先跑一次生物识别，确认用户本人
      final auth = ref.read(biometricAuthProvider);
      final ok = await auth.authenticate(reason: '启用生物识别快捷解锁');
      if (!ok) return;
    }
    await pin.setBiometricEnabled(v);
    if (!mounted) return;
    setState(() => _biometricEnabled = v);
  }

  Future<void> _changePin() async {
    // 先验证当前 PIN，再创建新 PIN
    final current = await _promptPin(
      title: '验证当前 PIN',
      subtitle: '',
      verify: true,
    );
    if (current == null) return;
    final next = await _promptPin(
      title: '创建新 PIN',
      subtitle: '请输入 6 位数字',
      verify: false,
    );
    if (next == null) return;
    final confirm = await _promptPin(
      title: '再次输入以确认',
      subtitle: '',
      verify: false,
    );
    if (confirm == null) return;
    if (confirm != next) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入不一致，已取消')),
      );
      return;
    }
    await ref.read(pinStoreProvider).setPin(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN 已更新')),
    );
  }

  Future<String?> _promptPin({
    required String title,
    required String subtitle,
    required bool verify,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GwpColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PinPromptSheet(
        title: title,
        subtitle: subtitle,
        verify: verify,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN 与指纹')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: GwpColors.actionPrimary))
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: GwpSpacing.base,
                vertical: GwpSpacing.md,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: GwpColors.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GwpColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.pin_outlined),
                        title: const Text('修改 PIN'),
                        subtitle: const Text('先验证当前 PIN，再设置新 PIN'),
                        trailing: const Icon(Icons.chevron_right, size: 18, color: GwpColors.textMuted),
                        onTap: _changePin,
                      ),
                      const Divider(height: 1, color: GwpColors.border),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: const Text('生物识别快捷解锁'),
                        subtitle: Text(_biometricDeviceReady
                            ? '解锁时优先弹出指纹 / Face ID，失败时回落 PIN'
                            : '当前设备未注册生物识别'),
                        value: _biometricEnabled && _biometricDeviceReady,
                        onChanged: _biometricDeviceReady ? _toggleBiometric : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PIN 输入 BottomSheet（用于修改流程中的三次输入）
// ─────────────────────────────────────────────────────────────────

class _PinPromptSheet extends ConsumerStatefulWidget {
  const _PinPromptSheet({
    required this.title,
    required this.subtitle,
    required this.verify,
  });

  final String title;
  final String subtitle;

  /// true 表示需要先校验当前 PIN 正确；false 表示仅收集输入
  final bool verify;

  @override
  ConsumerState<_PinPromptSheet> createState() => _PinPromptSheetState();
}

class _PinPromptSheetState extends ConsumerState<_PinPromptSheet> {
  static const int _pinLen = 6;
  String _input = '';
  String? _error;
  bool _busy = false;

  Future<void> _onKey(String k) async {
    if (_busy || _input.length >= _pinLen) return;
    setState(() {
      _input += k;
      _error = null;
    });
    HapticFeedback.selectionClick();
    if (_input.length == _pinLen) {
      await _finalize();
    }
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _finalize() async {
    if (!widget.verify) {
      Navigator.of(context).pop(_input);
      return;
    }
    setState(() => _busy = true);
    final r = await ref.read(pinStoreProvider).verifyPin(_input);
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pop(_input);
      return;
    }
    setState(() {
      _input = '';
      _busy = false;
      _error = r.remainingAttempts > 0
          ? 'PIN 不正确，还可尝试 ${r.remainingAttempts} 次'
          : 'PIN 不正确';
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GwpSpacing.base,
            vertical: GwpSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GwpColors.borderStrong,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: GwpColors.textPrimary)),
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.subtitle,
                    style: const TextStyle(fontSize: 12, color: GwpColors.textSecondary)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_pinLen, (i) {
                  final on = i < _input.length;
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? GwpColors.actionPrimary : Colors.transparent,
                      border: Border.all(
                        color: on ? GwpColors.actionPrimary : GwpColors.borderStrong,
                        width: 1.3,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              if (_error != null)
                Text(_error!, style: const TextStyle(fontSize: 12, color: GwpColors.negative))
              else
                const SizedBox(height: 16),
              const SizedBox(height: 12),
              _CompactKeypad(
                onDigit: _onKey,
                onBackspace: _onBackspace,
                enabled: !_busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactKeypad extends StatelessWidget {
  const _CompactKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => Expanded(
          child: AspectRatio(
            aspectRatio: 2.0,
            child: InkResponse(
              onTap: enabled ? () => onDigit(d) : null,
              radius: 32,
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: GwpColors.textPrimary,
                    fontFeatures: GwpTypo.tabularFigures,
                  ),
                ),
              ),
            ),
          ),
        );
    Widget backspace() => Expanded(
          child: AspectRatio(
            aspectRatio: 2.0,
            child: InkResponse(
              onTap: enabled ? onBackspace : null,
              radius: 32,
              child: const Center(
                child: Icon(Icons.backspace_outlined,
                    size: 20, color: GwpColors.textSecondary),
              ),
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [digit('1'), digit('2'), digit('3')]),
        Row(children: [digit('4'), digit('5'), digit('6')]),
        Row(children: [digit('7'), digit('8'), digit('9')]),
        Row(children: [const Spacer(), digit('0'), backspace()]),
      ],
    );
  }
}
