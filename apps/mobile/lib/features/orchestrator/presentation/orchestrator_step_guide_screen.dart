import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/room_section_model.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_detail_notifier.dart';

// ---------------------------------------------------------------------------
// BoundingBox overlay painter
// ---------------------------------------------------------------------------

class _BoundingBoxPainter extends CustomPainter {
  const _BoundingBoxPainter({required this.boundingBox});

  final SectionBoundingBox boundingBox;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      boundingBox.x * size.width,
      boundingBox.y * size.height,
      boundingBox.width * size.width,
      boundingBox.height * size.height,
    );

    // Filled semi-transparent tint inside the bounding box
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFFE84040).withValues(alpha: 0.18),
    );

    // Solid border
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFE84040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Corner accents for premium look
    const double cornerLen = 12;
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), paint);
  }

  @override
  bool shouldRepaint(_BoundingBoxPainter oldDelegate) =>
      oldDelegate.boundingBox.x != boundingBox.x ||
      oldDelegate.boundingBox.y != boundingBox.y ||
      oldDelegate.boundingBox.width != boundingBox.width ||
      oldDelegate.boundingBox.height != boundingBox.height;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OrchestratorStepGuideScreen extends ConsumerStatefulWidget {
  const OrchestratorStepGuideScreen({
    super.key,
    required this.planId,
    required this.groupId,
    required this.stepId,
  });

  final String planId;
  final String groupId;
  final String stepId;

  @override
  ConsumerState<OrchestratorStepGuideScreen> createState() =>
      _OrchestratorStepGuideScreenState();
}

class _OrchestratorStepGuideScreenState
    extends ConsumerState<OrchestratorStepGuideScreen> {
  bool _initialLoadCompleted = false;
  late final PageController _pageController;
  int _currentPage = 0;
  bool _completing = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .load(widget.planId)
          .whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  OrchestratorStepModel? _findStep(OrchestratorPlanModel plan) {
    for (final group in plan.taskGroups) {
      if (group.groupId == widget.groupId) {
        for (final step in group.steps) {
          if (step.stepId == widget.stepId) return step;
        }
      }
    }
    return null;
  }

  OrchestratorTaskGroupModel? _findGroup(OrchestratorPlanModel plan) {
    for (final group in plan.taskGroups) {
      if (group.groupId == widget.groupId) return group;
    }
    return null;
  }

  Future<void> _completeStep(OrchestratorPlanModel plan) async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .completeStep(
            groupId: widget.groupId,
            stepId: widget.stepId,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step completed!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Find next pending step in the same group
      final updatedState = ref.read(orchestratorDetailNotifierProvider);
      final updatedPlan = updatedState.valueOrNull;
      if (updatedPlan != null) {
        final group = _findGroup(updatedPlan);
        final steps = group?.steps ?? <OrchestratorStepModel>[];
        OrchestratorStepModel? nextStep;
        for (final s in steps) {
          if (s.isPending) {
            nextStep = s;
            break;
          }
        }
        if (nextStep != null && mounted) {
          context.pushReplacement(
            '/orchestrator/plans/${widget.planId}/groups/${widget.groupId}/steps/${nextStep.stepId}',
          );
          return;
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orchestratorDetailNotifierProvider);
    final showInitialSkeleton = !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton ? const AsyncLoading<OrchestratorPlanModel?>() : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: renderState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OrchestratorDetailNotifier.errorMessage(e),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref
                    .read(orchestratorDetailNotifierProvider.notifier)
                    .load(widget.planId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Text(
                'Plan not found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          final step = _findStep(plan);
          if (step == null) {
            return const Center(
              child: Text(
                'Step not found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return _buildGuide(context, plan, step);
        },
      ),
    );
  }

  Widget _buildGuide(
    BuildContext context,
    OrchestratorPlanModel plan,
    OrchestratorStepModel step,
  ) {
    return Column(
      children: [
        // AppBar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    step.itemName,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panel labels row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _PanelLabel(label: 'Room', index: 0, current: _currentPage),
              const SizedBox(width: AppSpacing.sm),
              _PanelLabel(label: 'Section', index: 1, current: _currentPage),
              const SizedBox(width: AppSpacing.sm),
              _PanelLabel(label: 'Item', index: 2, current: _currentPage),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // PageView — main panels
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _Panel1Room(step: step),
              _Panel2Section(step: step),
              _Panel3Item(step: step),
            ],
          ),
        ),
        // Page indicator dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppColors.accent
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        // Bottom action bar
        _BottomActionBar(
          step: step,
          noteController: _noteController,
          completing: _completing,
          onComplete: () => _completeStep(plan),
          onNext: _currentPage < 2
              ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  )
              : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Panel 1 — Find the Room
// ---------------------------------------------------------------------------

class _Panel1Room extends StatelessWidget {
  const _Panel1Room({required this.step});

  final OrchestratorStepModel step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: step.roomPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: step.roomPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _PhotoPlaceholder(
                        icon: Icons.meeting_room_outlined,
                      ),
                      errorWidget: (_, __, ___) => _PhotoPlaceholder(
                        icon: Icons.meeting_room_outlined,
                      ),
                    )
                  : _PhotoPlaceholder(icon: Icons.meeting_room_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.meeting_room_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GO TO ROOM',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.roomName ?? 'Unknown room',
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel 2 — Find the Section
// ---------------------------------------------------------------------------

class _Panel2Section extends StatelessWidget {
  const _Panel2Section({required this.step});

  final OrchestratorStepModel step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: step.sectionPhoto != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: step.sectionPhoto!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _PhotoPlaceholder(
                            icon: Icons.view_compact_outlined,
                          ),
                          errorWidget: (_, __, ___) => _PhotoPlaceholder(
                            icon: Icons.view_compact_outlined,
                          ),
                        ),
                        if (step.boundingBox != null)
                          CustomPaint(
                            painter: _BoundingBoxPainter(
                              boundingBox: step.boundingBox!,
                            ),
                          ),
                      ],
                    )
                  : _PhotoPlaceholder(icon: Icons.view_compact_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.view_compact_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIND THE SECTION',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.sectionFurnitureName ??
                            step.sectionCode ??
                            'Unknown section',
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (step.sectionCode != null &&
                          step.sectionFurnitureName != null)
                        Text(
                          'Code: ${step.sectionCode}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel 3 — The Item
// ---------------------------------------------------------------------------

class _Panel3Item extends StatelessWidget {
  const _Panel3Item({required this.step});

  final OrchestratorStepModel step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: step.itemPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: step.itemPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _PhotoPlaceholder(icon: Icons.inventory_2_outlined),
                      errorWidget: (_, __, ___) =>
                          _PhotoPlaceholder(icon: Icons.inventory_2_outlined),
                    )
                  : _PhotoPlaceholder(icon: Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.itemName,
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.itemCategory,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  step.instruction,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.step,
    required this.noteController,
    required this.completing,
    required this.onComplete,
    required this.onNext,
  });

  final OrchestratorStepModel step;
  final TextEditingController noteController;
  final bool completing;
  final VoidCallback onComplete;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLastPanel = onNext == null;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLastPanel) ...[
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)…',
                hintStyle: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 14,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: completing || step.isDone ? null : onComplete,
                icon: completing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Icon(
                        step.isDone
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                label: Text(step.isDone ? 'Already Done' : 'Mark Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      step.isDone ? AppColors.onSurfaceVariant : AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel label tab
// ---------------------------------------------------------------------------

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({
    required this.label,
    required this.index,
    required this.current,
  });

  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared photo placeholder
// ---------------------------------------------------------------------------

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'No photo available',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
