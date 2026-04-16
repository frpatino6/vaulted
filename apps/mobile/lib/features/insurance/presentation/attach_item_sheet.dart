import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

typedef OnAttachedCallback = Future<void> Function(
    String itemId, double coveredValue, String currency);

/// Bottom sheet for attaching an inventory item to an insurance policy.
/// The user enters the MongoDB ObjectId of the item and the covered value.
class AttachItemSheet extends StatefulWidget {
  const AttachItemSheet({
    super.key,
    required this.policyId,
    required this.onAttached,
  });

  final String policyId;
  final OnAttachedCallback onAttached;

  @override
  State<AttachItemSheet> createState() => _AttachItemSheetState();
}

class _AttachItemSheetState extends State<AttachItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemIdCtrl = TextEditingController();
  final _coveredValueCtrl = TextEditingController();
  String _currency = 'USD';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _itemIdCtrl.dispose();
    _coveredValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final coveredValue = double.tryParse(_coveredValueCtrl.text.trim());
    if (coveredValue == null) {
      setState(() => _error = 'Enter a valid covered value.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onAttached(
        _itemIdCtrl.text.trim(),
        coveredValue,
        _currency,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Attach Item',
              style: AppTypography.titleLarge
                  .copyWith(color: AppColors.onBackground),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter the item ID and the covered value for this policy.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),

            // Item ID field
            TextFormField(
              controller: _itemIdCtrl,
              style: TextStyle(color: AppColors.onBackground),
              decoration: _inputDecoration('Item ID (24-char MongoDB ID)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 24) return 'Must be 24 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Covered value + currency row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _coveredValueCtrl,
                    style: TextStyle(color: AppColors.onBackground),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration('Covered Value'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      if ((double.tryParse(v.trim()) ?? 0) <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    dropdownColor: AppColors.surfaceVariant,
                    style: TextStyle(color: AppColors.onBackground),
                    decoration: _inputDecoration('Currency'),
                    items: ['USD', 'EUR', 'GBP']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('Attach Item',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorStyle: TextStyle(color: AppColors.error),
    );
  }
}
