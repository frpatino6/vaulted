import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/insurance_policy_model.dart';
import '../data/insurance_repository_provider.dart';
import '../domain/insurance_list_notifier.dart';

class InsuranceFormScreen extends ConsumerStatefulWidget {
  const InsuranceFormScreen({super.key, this.policy});

  /// Pass existing policy to pre-fill for editing. Null = create mode.
  final InsurancePolicyModel? policy;

  @override
  ConsumerState<InsuranceFormScreen> createState() =>
      _InsuranceFormScreenState();
}

class _InsuranceFormScreenState extends ConsumerState<InsuranceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _providerCtrl;
  late final TextEditingController _policyNumberCtrl;
  late final TextEditingController _totalCoverageCtrl;
  late final TextEditingController _premiumCtrl;
  late final TextEditingController _notesCtrl;

  String _coverageType = 'all-risk';
  String _currency = 'USD';
  String _status = 'active';
  DateTime? _startDate;
  DateTime? _expiresAt;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.policy != null;

  static const _coverageTypes = [
    ('all-risk', 'All Risk'),
    ('named-peril', 'Named Peril'),
    ('liability', 'Liability'),
    ('scheduled', 'Scheduled'),
  ];

  static const _statuses = [
    ('active', 'Active'),
    ('expired', 'Expired'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.policy;
    _providerCtrl = TextEditingController(text: p?.provider ?? '');
    _policyNumberCtrl = TextEditingController(text: p?.policyNumber ?? '');
    _totalCoverageCtrl = TextEditingController(
      text: p != null ? p.totalCoverageAmount.toStringAsFixed(2) : '',
    );
    _premiumCtrl = TextEditingController(
      text: p?.premium != null ? p!.premium!.toStringAsFixed(2) : '',
    );
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    if (p != null) {
      _coverageType = p.coverageType;
      _currency = p.currency;
      _status = p.status;
      _startDate = DateTime.tryParse(p.startDate);
      _expiresAt = DateTime.tryParse(p.expiresAt);
    }
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _policyNumberCtrl.dispose();
    _totalCoverageCtrl.dispose();
    _premiumCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_expiresAt ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
            onSurface: AppColors.onBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _expiresAt = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate == null) {
      setState(() => _error = 'Select a start date.');
      return;
    }
    if (_expiresAt == null) {
      setState(() => _error = 'Select an expiry date.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(insuranceRepositoryProvider);
      if (_isEdit) {
        await repo.updatePolicy(
          widget.policy!.id,
          provider: _providerCtrl.text.trim(),
          policyNumber: _policyNumberCtrl.text.trim(),
          coverageType: _coverageType,
          totalCoverageAmount:
              double.parse(_totalCoverageCtrl.text.trim()),
          premium: _premiumCtrl.text.trim().isEmpty
              ? null
              : double.tryParse(_premiumCtrl.text.trim()),
          startDate: _startDate!.toIso8601String(),
          expiresAt: _expiresAt!.toIso8601String(),
          status: _status,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      } else {
        await repo.createPolicy(
          provider: _providerCtrl.text.trim(),
          policyNumber: _policyNumberCtrl.text.trim(),
          coverageType: _coverageType,
          totalCoverageAmount:
              double.parse(_totalCoverageCtrl.text.trim()),
          premium: _premiumCtrl.text.trim().isEmpty
              ? null
              : double.tryParse(_premiumCtrl.text.trim()),
          currency: _currency,
          startDate: _startDate!.toIso8601String(),
          expiresAt: _expiresAt!.toIso8601String(),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      }

      // Refresh list before popping
      await ref.read(insuranceListNotifierProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = InsuranceListNotifier.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          _isEdit ? 'Edit Policy' : 'New Policy',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildTextField(
              controller: _providerCtrl,
              label: 'Provider',
              hint: 'e.g. Chubb, AIG',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildTextField(
              controller: _policyNumberCtrl,
              label: 'Policy Number',
              hint: 'e.g. CHB-2024-001',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Coverage type
            _buildDropdown<String>(
              label: 'Coverage Type',
              value: _coverageType,
              items: _coverageTypes
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _coverageType = v ?? 'all-risk'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Total coverage + currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _totalCoverageCtrl,
                    label: 'Total Coverage',
                    hint: '1000000',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Currency',
                    value: _currency,
                    items: ['USD', 'EUR', 'GBP']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'USD'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            _buildTextField(
              controller: _premiumCtrl,
              label: 'Annual Premium (optional)',
              hint: '5000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Must be ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDateTile(
                    label: 'Expiry Date',
                    date: _expiresAt,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_isEdit) ...[
              _buildDropdown<String>(
                label: 'Status',
                value: _status,
                items: _statuses
                    .map((s) =>
                        DropdownMenuItem(value: s.$1, child: Text(s.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            _buildTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'Any additional information…',
              maxLines: 3,
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            ElevatedButton(
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
                  : Text(
                      _isEdit ? 'Save Changes' : 'Create Policy',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.onBackground),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.5)),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorStyle: TextStyle(color: AppColors.error),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: AppColors.surfaceVariant,
      style: TextStyle(color: AppColors.onBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final fmt = DateFormat('MMM d, yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  date != null ? fmt.format(date) : 'Select date',
                  style: AppTypography.bodySmall.copyWith(
                    color: date != null
                        ? AppColors.onBackground
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
