import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/household_member_model.dart';
import '../domain/household_members_notifier.dart';

class HouseholdMembersScreen extends ConsumerWidget {
  const HouseholdMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(householdMembersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: const Text('Household Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        label: const Text('Add member'),
        icon: const Icon(Icons.person_add_alt_1),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(householdMembersNotifierProvider.notifier).refresh(),
        child: state.when(
          data: (members) {
            if (members.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('No household members yet')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (context, index) {
                final member = members[index];
                return _MemberTile(member: member);
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemCount: members.length,
            );
          },
          loading: () => const AppScreenSkeleton(showHeader: false),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                HouseholdMembersNotifier.message(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateHouseholdMemberSheet(),
    );
    ref.invalidate(householdMembersNotifierProvider);
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final HouseholdMemberModel member;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
          child: Text(
            member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
            style: const TextStyle(color: AppColors.accent),
          ),
        ),
        title: Text(member.name),
        subtitle: Text(
          [
            if (member.relationship != null && member.relationship!.isNotEmpty)
              member.relationship!,
            member.isMinor ? 'Minor' : 'Adult',
          ].join(' • '),
        ),
      ),
    );
  }
}

class _CreateHouseholdMemberSheet extends ConsumerStatefulWidget {
  const _CreateHouseholdMemberSheet();

  @override
  ConsumerState<_CreateHouseholdMemberSheet> createState() =>
      _CreateHouseholdMemberSheetState();
}

class _CreateHouseholdMemberSheetState
    extends ConsumerState<_CreateHouseholdMemberSheet> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _isMinor = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add household member',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isMinor,
              onChanged: (value) => setState(() => _isMinor = value),
              title: const Text('Minor'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(householdMembersNotifierProvider.notifier).createMember(
        name: name,
        relationship: _relationshipController.text.trim(),
        isMinor: _isMinor,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
