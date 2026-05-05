import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import 'event_providers.dart';

class EventCreatePage extends ConsumerStatefulWidget {
  const EventCreatePage({super.key, this.initialDay});

  /// 可通过日历页传入初始日，新建事件默认使用该日期作为 triggerTime。
  final DateTime? initialDay;

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _eventTypeCtrl = TextEditingController();
  final _relatedIdCtrl = TextEditingController();
  final _handlerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  RelatedModel _related = RelatedModel.account;
  EventStatus _status = EventStatus.pending;
  EventPriority? _priority;
  HandlingStatus? _handling;
  AckRequirement _ackRequirement = AckRequirement.notApplicable;
  DateTime? _dueAt;
  late DateTime _trigger;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _trigger = widget.initialDay == null
        ? now
        : DateTime(widget.initialDay!.year, widget.initialDay!.month,
            widget.initialDay!.day, now.hour, now.minute);
  }

  @override
  void dispose() {
    _eventTypeCtrl.dispose();
    _relatedIdCtrl.dispose();
    _handlerCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _trigger,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_trigger),
    );
    if (!mounted) return;
    setState(() {
      _trigger = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _trigger.hour,
        t?.minute ?? _trigger.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final uuid = ref.read(uuidGeneratorProvider);
    final event = DomainEvent(
      id: uuid(),
      eventType: _eventTypeCtrl.text.trim(),
      relatedModel: _related,
      relatedId: _relatedIdCtrl.text.trim(),
      triggerTime: _trigger,
      dueAt: _dueAt,
      priority: _priority,
      status: _status,
      handlingStatus: _handling,
      handler: _handlerCtrl.text.trim().isEmpty
          ? null
          : _handlerCtrl.text.trim(),
      handlingNote: _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
      ackRequirement: _ackRequirement,
      createdAt: now,
      updatedAt: now,
    );
    final r = await ref.read(eventRepositoryProvider).record(event);
    if (!mounted) return;
    setState(() => _submitting = false);
    r.when(
      ok: (_) => context.pop(),
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: ${errorToMessage(e)}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String p(int n) => n.toString().padLeft(2, '0');
    final tLabel =
        '${_trigger.year}-${p(_trigger.month)}-${p(_trigger.day)} '
        '${p(_trigger.hour)}:${p(_trigger.minute)}';
    return Scaffold(
      appBar: AppBar(title: const Text('新建事件')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _eventTypeCtrl,
              decoration: const InputDecoration(
                labelText: '事件类型 *',
                border: OutlineInputBorder(),
                helperText: '建议用点分命名，如 account.opened / asset.valuation.updated',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RelatedModel>(
              initialValue: _related,
              decoration: const InputDecoration(
                labelText: '关联模型 *',
                border: OutlineInputBorder(),
              ),
              items: RelatedModel.values
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _related = v ?? _related),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _relatedIdCtrl,
              decoration: const InputDecoration(
                labelText: '关联对象 ID *',
                border: OutlineInputBorder(),
                helperText: '对应 ${'账户/资产/卡/通道'} 实例的 id 或业务标识',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '触发时间 *',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(tLabel)),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('修改'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EventStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: '状态 *',
                border: OutlineInputBorder(),
              ),
              items: EventStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EventPriority?>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: '优先级（可选）',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<EventPriority?>>[
                const DropdownMenuItem(value: null, child: Text('— 未指定 —')),
                ...EventPriority.values.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.labelBilingual)),
                ),
              ],
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HandlingStatus?>(
              initialValue: _handling,
              decoration: const InputDecoration(
                labelText: '处理状态（可选）',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<HandlingStatus?>>[
                const DropdownMenuItem(value: null, child: Text('— 未指定 —')),
                ...HandlingStatus.values.map(
                  (h) => DropdownMenuItem(value: h, child: Text(h.labelBilingual)),
                ),
              ],
              onChanged: (v) => setState(() => _handling = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _handlerCtrl,
              decoration: const InputDecoration(
                labelText: '处理人（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '处理备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AckRequirement>(
              initialValue: _ackRequirement,
              decoration: const InputDecoration(
                labelText: '是否需要用户确认',
                border: OutlineInputBorder(),
                helperText: 'REQUIRED 的事件会进入首页「待确认」聚合',
              ),
              items: AckRequirement.values
                  .map((a) =>
                      DropdownMenuItem(value: a, child: Text(a.labelBilingual)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _ackRequirement = v ?? _ackRequirement),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '截止时间（可选）',
                border: OutlineInputBorder(),
                helperText: 'REQUIRED 类事件建议填写，如账单到期日',
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueAt == null
                          ? '未设置'
                          : '${_dueAt!.year}-${p(_dueAt!.month)}-${p(_dueAt!.day)}',
                    ),
                  ),
                  if (_dueAt != null)
                    IconButton(
                      tooltip: '清除',
                      onPressed: () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dueAt ?? _trigger,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (!mounted) return;
                      if (d != null) setState(() => _dueAt = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('选择'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
