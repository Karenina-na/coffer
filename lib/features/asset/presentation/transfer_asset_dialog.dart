import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/account.dart';
import '../../../domain/entities/asset.dart';

class TransferResult {
  const TransferResult({required this.targetAccountId, this.quantity});
  final String targetAccountId;
  final Decimal? quantity;
}

class TransferDialog extends StatefulWidget {
  const TransferDialog({
    super.key,
    required this.asset,
    required this.accounts,
  });
  final Asset asset;
  final List<Account> accounts;

  @override
  State<TransferDialog> createState() => TransferDialogState();
}

class TransferDialogState extends State<TransferDialog> {
  String? _targetId;
  final _qtyCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return AlertDialog(
      title: const Text('划转资产'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前资产：${a.assetCode ?? a.id} (${a.quantity} ${a.currency})'),
            const SizedBox(height: 16),
            const Text('目标账户：'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _targetId,
              onChanged: (v) => setState(() => _targetId = v),
              child: Column(
                children: widget.accounts
                    .map(
                      (acc) => RadioListTile<String>(
                        title: Text(acc.institutionName),
                        subtitle: Text(acc.accountNo ?? acc.id),
                        value: acc.id,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: '划转数量（留空为全部）',
                helperText: '最大 ${a.quantity} ${a.currency}',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _targetId == null
              ? null
              : () {
                  final qtyText = _qtyCtrl.text.trim();
                  Decimal? qty;
                  if (qtyText.isNotEmpty) {
                    qty = Decimal.tryParse(qtyText);
                    if (qty == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('数量格式无效，请输入有效的数字')),
                      );
                      return;
                    }
                  }
                  Navigator.pop(
                    context,
                    TransferResult(targetAccountId: _targetId!, quantity: qty),
                  );
                },
          child: const Text('确认划转'),
        ),
      ],
    );
  }
}
