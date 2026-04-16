import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/insurance_ai_model.dart';
import '../domain/insurance_ai_notifier.dart';

class ClaimDraftScreen extends ConsumerStatefulWidget {
  const ClaimDraftScreen({super.key, required this.policyId});

  final String policyId;

  @override
  ConsumerState<ClaimDraftScreen> createState() => _ClaimDraftScreenState();
}

class _ClaimDraftScreenState extends ConsumerState<ClaimDraftScreen> {
  final _descCtrl = TextEditingController();
  final _itemIdCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _itemIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe what happened.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final itemId = _itemIdCtrl.text.trim().isEmpty ? null : _itemIdCtrl.text.trim();

    setState(() => _submitted = true);

    await ref.read(claimDraftNotifierProvider.notifier).draft(
          widget.policyId,
          itemId,
          desc,
        );

    final state = ref.read(claimDraftNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ClaimDraftNotifier.message(state.error!)),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _submitted = false);
    }
  }

  void _reset() {
    ref.invalidate(claimDraftNotifierProvider);
    setState(() => _submitted = false);
  }

  void _copyBody(String body) {
    Clipboard.setData(ClipboardData(text: body));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Letter copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimState = ref.watch(claimDraftNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Claim Draft',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.onBackground),
        ),
      ),
      body: SafeArea(
        child: claimState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              )
            : claimState.hasValue && claimState.value != null && _submitted
                ? _ResultPhase(
                    draft: claimState.value!,
                    onCopy: () => _copyBody(claimState.value!.body),
                    onReset: _reset,
                  )
                : _InputPhase(
                    descCtrl: _descCtrl,
                    itemIdCtrl: _itemIdCtrl,
                    onGenerate: _generate,
                  ),
      ),
    );
  }
}

// ─── Phase 1: Input ───────────────────────────────────────────────────────────

class _InputPhase extends StatelessWidget {
  const _InputPhase({
    required this.descCtrl,
    required this.itemIdCtrl,
    required this.onGenerate,
  });

  final TextEditingController descCtrl;
  final TextEditingController itemIdCtrl;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe what happened',
            style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Provide details about the incident so AI can draft a formal claim letter.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          // Incident description
          TextField(
            controller: descCtrl,
            style: TextStyle(color: AppColors.onBackground),
            maxLines: 6,
            maxLength: 2000,
            decoration: _inputDecoration(
              'Incident description',
              hint: 'e.g. Water damage caused by a burst pipe in the main bathroom on April 14...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Optional item ID
          Text(
            'Item ID (optional)',
            style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If the claim is for a specific item, enter its 24-character inventory ID.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: itemIdCtrl,
            style: TextStyle(color: AppColors.onBackground),
            maxLength: 24,
            decoration: _inputDecoration('Item ID (24-char MongoDB ID, optional)'),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(
                'Generate Draft',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
      counterStyle: TextStyle(color: AppColors.onSurfaceVariant),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorStyle: TextStyle(color: AppColors.error),
    );
  }
}

// ─── Phase 2: Result ──────────────────────────────────────────────────────────

class _ResultPhase extends StatelessWidget {
  const _ResultPhase({
    required this.draft,
    required this.onCopy,
    required this.onReset,
  });

  final ClaimDraftModel draft;
  final VoidCallback onCopy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject line (copyable)
          Text(
            'Subject',
            style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: draft.subject));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subject copied.')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      draft.subject,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onBackground),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.copy_outlined,
                      size: 16, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Letter body
          Text(
            'Letter',
            style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.onSurfaceVariant.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              draft.body,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Key points
          if (draft.keyPoints.isNotEmpty) ...[
            Text(
              'Key Points',
              style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...draft.keyPoints.map(
              (pt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        pt,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Next steps
          if (draft.nextSteps.isNotEmpty) ...[
            Text(
              'Next Steps',
              style: AppTypography.titleMedium.copyWith(color: AppColors.onBackground),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...draft.nextSteps.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: AppSpacing.sm, top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCopy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: Text(
                    'Copy Letter',
                    style: AppTypography.labelLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: BorderSide(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_outlined, size: 16),
                  label: Text(
                    'Start Over',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
