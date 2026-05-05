import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../../core/auth/pin_store.dart';
import '../../../core/ui/design_tokens.dart';

/// 生物识别实现 Provider；非 iOS/Android（包括测试）自动降级为放行。
final biometricAuthProvider = Provider<BiometricAuth>((ref) {
  if (kIsWeb) return const AllowAllBiometric();
  try {
    if (Platform.isIOS || Platform.isAndroid) return LocalAuthBiometric();
  } catch (_) {
    // Platform 不可用（纯 Dart 测试环境）
  }
  return const AllowAllBiometric();
});

/// 全局 PIN 存储 Provider。
final pinStoreProvider = Provider<PinStore>((ref) => PinStore());

/// 是否已解锁；全局单例状态。
class UnlockNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

final isUnlockedProvider = NotifierProvider<UnlockNotifier, bool>(
  UnlockNotifier.new,
);

/// 解锁门卫：
/// - 未设置 PIN → 强制进入创建 PIN 流程
/// - 已设置 PIN + 启用生物识别 → 优先弹指纹；失败/取消回落 PIN 键盘
/// - 已设置 PIN + 未启用 → 直接 PIN 键盘
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  _GateMode _mode = _GateMode.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final pin = ref.read(pinStoreProvider);
    final hasPin = await pin.hasPin();
    if (!mounted) return;
    setState(() => _mode = hasPin ? _GateMode.lock : _GateMode.setup);
  }

  void _onUnlocked() {
    if (!mounted) return;
    ref.read(isUnlockedProvider.notifier).unlock();
  }

  void _onPinCreated() {
    if (!mounted) return;
    setState(() => _mode = _GateMode.lock);
    // 创建后紧接着进入锁屏（用户立即用新 PIN 解锁一次）
    // 也可直接放行，但保留一次确认更稳妥
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(isUnlockedProvider);
    final overlay = switch (_mode) {
      _GateMode.loading => const Scaffold(
        backgroundColor: GwpColors.canvas,
        body: SizedBox.shrink(),
      ),
      _GateMode.setup => _PinSetupScreen(
        key: const ValueKey('setup'),
        onDone: _onPinCreated,
      ),
      _GateMode.lock => _LockScreen(
        key: const ValueKey('lock'),
        onUnlocked: _onUnlocked,
      ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: !unlocked,
          child: TickerMode(enabled: unlocked, child: widget.child),
        ),
        if (!unlocked) Positioned.fill(child: overlay),
      ],
    );
  }
}

enum _GateMode { loading, setup, lock }

// ─────────────────────────────────────────────────────────────────
// 锁屏：PIN 键盘 + 可选指纹图标
// ─────────────────────────────────────────────────────────────────

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  String _input = '';
  String? _error;
  bool _busy = false;
  bool _biometricAvailable = false;
  int _lockUntilMs = 0;
  Timer? _lockTicker;

  static const int _pinLen = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final pin = ref.read(pinStoreProvider);
    final auth = ref.read(biometricAuthProvider);
    final enabled = await pin.isBiometricEnabled();
    final available = enabled && await auth.canCheckBiometrics();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
    });
    if (available) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_busy || _isLocked) return;
    setState(() => _busy = true);
    final auth = ref.read(biometricAuthProvider);
    final ok = await auth.authenticate(reason: '验证身份以继续');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onUnlocked();
  }

  bool get _isLocked => _lockUntilMs > DateTime.now().millisecondsSinceEpoch;
  int get _lockSecondsLeft =>
      ((_lockUntilMs - DateTime.now().millisecondsSinceEpoch) / 1000)
          .ceil()
          .clamp(0, 9999);

  void _startLockTicker() {
    _lockTicker?.cancel();
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (!_isLocked) {
        t.cancel();
        setState(() => _lockUntilMs = 0);
        return;
      }
      setState(() {});
    });
  }

  Future<void> _submit() async {
    if (_busy || _isLocked) return;
    setState(() => _busy = true);
    try {
      final store = ref.read(pinStoreProvider);
      final r = await store.verifyPin(_input);
      if (!mounted) return;
      if (r.ok) {
        widget.onUnlocked();
        return;
      }
      if (r.lockedUntilMs > DateTime.now().millisecondsSinceEpoch) {
        setState(() {
          _input = '';
          _lockUntilMs = r.lockedUntilMs;
          _error = null;
        });
        _startLockTicker();
        HapticFeedback.heavyImpact();
        return;
      }
      setState(() {
        _input = '';
        _error = r.remainingAttempts > 0
            ? 'PIN 不正确，还可尝试 ${r.remainingAttempts} 次'
            : 'PIN 不正确';
      });
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onKey(String k) {
    if (_isLocked || _busy) return;
    if (_input.length >= _pinLen) return;
    setState(() {
      _input += k;
      _error = null;
    });
    HapticFeedback.selectionClick();
    if (_input.length == _pinLen) _submit();
  }

  void _onBackspace() {
    if (_isLocked || _busy || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(
              Icons.lock_outline,
              size: 56,
              color: GwpColors.actionPrimary,
            ),
            const SizedBox(height: 16),
            const Text(
              '输入 PIN 码',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _PinDots(filled: _input.length, total: _pinLen, busy: _busy),
            const SizedBox(height: 16),
            if (_busy)
              const _BusyHint(text: '校验中...')
            else if (_isLocked)
              Text(
                '尝试过多，$_lockSecondsLeft 秒后再试',
                style: const TextStyle(fontSize: 13, color: GwpColors.negative),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: GwpColors.negative),
              )
            else
              const SizedBox(height: 18),
            const Spacer(flex: 3),
            _NumericKeypad(
              onDigit: _onKey,
              onBackspace: _onBackspace,
              leftAction: _biometricAvailable
                  ? _KeypadAction(
                      icon: Icons.fingerprint,
                      label: '指纹',
                      onTap: _tryBiometric,
                    )
                  : null,
              enabled: !_isLocked && !_busy,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 首次设置 PIN：两步（创建 + 确认）
// ─────────────────────────────────────────────────────────────────

class _PinSetupScreen extends ConsumerStatefulWidget {
  const _PinSetupScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<_PinSetupScreen> {
  static const int _pinLen = 6;
  String _input = '';
  String? _firstPin;
  String? _error;
  bool _busy = false; // setPin 真正在写存储
  bool _pending = false; // 切步 / 回退的短动画间隔，禁用输入但不显示 busy

  bool get _isConfirming => _firstPin != null;
  bool get _blocked => _busy || _pending;

  void _onKey(String k) {
    if (_blocked) return;
    if (_input.length >= _pinLen) return;
    setState(() {
      _input += k;
      _error = null;
    });
    HapticFeedback.selectionClick();
    if (_input.length == _pinLen) _next();
  }

  void _onBackspace() {
    if (_blocked || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _next() async {
    if (!_isConfirming) {
      setState(() => _pending = true);
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() {
        _firstPin = _input;
        _input = '';
        _pending = false;
      });
      return;
    }
    if (_input != _firstPin) {
      setState(() => _pending = true);
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _error = '两次输入不一致，请重新设置';
        _firstPin = null;
        _input = '';
        _pending = false;
      });
      return;
    }
    setState(() => _busy = true);
    final store = ref.read(pinStoreProvider);
    try {
      await store.setPin(_input);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '设置失败：$e';
        _firstPin = null;
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirming ? '再次输入以确认' : '创建 6 位 PIN 码';
    final subtitle = _isConfirming
        ? '确认后用于解锁应用'
        : '用于解锁应用，忘记 PIN 需要重新初始化（数据丢失）';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(
              Icons.pin_outlined,
              size: 56,
              color: GwpColors.actionPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: GwpColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PinDots(filled: _input.length, total: _pinLen, busy: _blocked),
            const SizedBox(height: 16),
            if (_busy)
              const _BusyHint(text: '设置中...')
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: GwpColors.negative),
              )
            else
              const SizedBox(height: 18),
            const Spacer(flex: 3),
            _NumericKeypad(
              onDigit: _onKey,
              onBackspace: _onBackspace,
              enabled: !_blocked,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  const _PinDots({
    required this.filled,
    required this.total,
    this.busy = false,
  });

  final int filled;
  final int total;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final on = i < filled;
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? GwpColors.actionPrimary : Colors.transparent,
            border: Border.all(
              color: on
                  ? GwpColors.actionPrimary
                  : (busy
                        ? GwpColors.actionPrimary.withValues(alpha: 0.4)
                        : GwpColors.borderStrong),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class _BusyHint extends StatelessWidget {
  const _BusyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: GwpColors.actionPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: GwpColors.textSecondary),
        ),
      ],
    );
  }
}

class _KeypadAction {
  const _KeypadAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.leftAction,
    this.enabled = true,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final _KeypadAction? leftAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) =>
        _KeypadButton(label: d, onTap: enabled ? () => onDigit(d) : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(children: [digit('1'), digit('2'), digit('3')]),
          const SizedBox(height: 12),
          Row(children: [digit('4'), digit('5'), digit('6')]),
          const SizedBox(height: 12),
          Row(children: [digit('7'), digit('8'), digit('9')]),
          const SizedBox(height: 12),
          Row(
            children: [
              _KeypadButton(
                icon: leftAction?.icon,
                label: leftAction?.label,
                onTap: (leftAction != null && enabled)
                    ? leftAction!.onTap
                    : null,
                subdued: true,
              ),
              digit('0'),
              _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: enabled ? onBackspace : null,
                subdued: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    this.onTap,
    this.subdued = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.8,
        child: InkResponse(
          onTap: onTap,
          radius: 40,
          child: Opacity(
            opacity: disabled ? 0.35 : 1,
            child: Center(
              child: icon != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: subdued
                              ? GwpColors.textSecondary
                              : GwpColors.textPrimary,
                        ),
                        if (label != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            label!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: GwpColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      label ?? '',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: GwpColors.textPrimary,
                        fontFeatures: GwpTypo.tabularFigures,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
