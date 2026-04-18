import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/domain/properties_notifier.dart';
import '../domain/users_notifier.dart';

const List<String> _inviteRoles = [
  'owner',
  'manager',
  'staff',
  'auditor',
  'guest',
];

/// Bottom sheet to invite a new user (email, role, property access, optional expiry).
class InviteUserSheet extends ConsumerStatefulWidget {
  const InviteUserSheet({super.key});

  @override
  ConsumerState<InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends ConsumerState<InviteUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String _role = 'manager';
  bool _propertySectionExpanded = true;
  final Set<String> _selectedPropertyIds = {};
  DateTime? _expiresAt;
  bool _submitting = false;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      final propertyIds = _role == 'staff' || _role == 'auditor'
          ? _selectedPropertyIds.toList()
          : <String>[];
      String? expiresAtStr;
      if (_expiresAt != null) {
        expiresAtStr = DateFormat('yyyy-MM-dd').format(_expiresAt!);
      }
      await ref.read(usersNotifierProvider.notifier).invite(
            email: email,
            role: _role,
            propertyIds: propertyIds,
            expiresAt: expiresAtStr,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UsersNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesNotifierProvider);
    final showPropertyAccess = _role == 'staff' || _role == 'auditor';
    final properties = propertiesState.valueOrNull ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Invite team member',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'colleague@example.com',
                    ),
                    enableInteractiveSelection: false,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _inviteRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r[0].toUpperCase() + r.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _role = value);
                    },
                  ),
                  if (showPropertyAccess) ...[
                    const SizedBox(height: AppSpacing.md),
                    ExpansionTile(
                      initiallyExpanded: _propertySectionExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _propertySectionExpanded = expanded),
                      title: Text(
                        'Property Access',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.onBackground,
                            ),
                      ),
                      children: properties.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Text(
                                  'No properties yet.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ]
                          : properties
                              .map(
                                (p) => CheckboxListTile(
                                  value: _selectedPropertyIds.contains(p.id),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedPropertyIds.add(p.id);
                                      } else {
                                        _selectedPropertyIds.remove(p.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    p.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.onBackground,
                                        ),
                                  ),
                                  activeColor: AppColors.accent,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Access expires (optional)',
                      ),
                      child: Text(
                        _expiresAt == null
                            ? 'Select date'
                            : DateFormat('MM/dd/yyyy').format(_expiresAt!),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _expiresAt == null
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onBackground,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Invite'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
