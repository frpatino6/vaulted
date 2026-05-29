import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Shared status data
// ---------------------------------------------------------------------------

class OrchestratorStatusInfo {
  const OrchestratorStatusInfo(this.color, this.label);
  final Color color;
  final String label;
}

OrchestratorStatusInfo planStatusInfo(String status) {
  switch (status) {
    case 'published':
      return const OrchestratorStatusInfo(AppColors.info, 'Published');
    case 'in_progress':
      return const OrchestratorStatusInfo(AppColors.warning, 'In Progress');
    case 'completed':
      return const OrchestratorStatusInfo(AppColors.statusActive, 'Completed');
    case 'cancelled':
      return const OrchestratorStatusInfo(AppColors.statusDisposed, 'Cancelled');
    default:
      return const OrchestratorStatusInfo(AppColors.onSurfaceVariant, 'Draft');
  }
}

OrchestratorStatusInfo groupStatusInfo(String status) {
  switch (status) {
    case 'in_progress':
      return const OrchestratorStatusInfo(AppColors.warning, 'In Progress');
    case 'completed':
      return const OrchestratorStatusInfo(AppColors.statusActive, 'Done');
    default:
      return const OrchestratorStatusInfo(AppColors.onSurfaceVariant, 'Pending');
  }
}

OrchestratorStatusInfo stepStatusInfo(String status) {
  switch (status) {
    case 'done':
      return const OrchestratorStatusInfo(AppColors.statusActive, 'Done');
    case 'skipped':
      return const OrchestratorStatusInfo(AppColors.accentBright, 'Skipped');
    case 'orphaned':
      return const OrchestratorStatusInfo(AppColors.error, 'Orphaned');
    default:
      return const OrchestratorStatusInfo(AppColors.onSurfaceVariant, 'Pending');
  }
}

// ---------------------------------------------------------------------------
// Shared badge/chip widgets
// ---------------------------------------------------------------------------

class OrchestratorStatusBadge extends StatelessWidget {
  const OrchestratorStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = planStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: AppTypography.labelSmall.copyWith(
          color: info.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OrchestratorGroupStatusChip extends StatelessWidget {
  const OrchestratorGroupStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = groupStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        info.label,
        style: AppTypography.labelSmall.copyWith(
          color: info.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OrchestratorStepStatusChip extends StatelessWidget {
  const OrchestratorStepStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = stepStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: AppTypography.labelSmall.copyWith(
          color: info.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium gradient progress ring
// ---------------------------------------------------------------------------

class OrchestratorProgressRing extends StatelessWidget {
  const OrchestratorProgressRing({
    super.key,
    required this.percentComplete,
    required this.completedSteps,
    required this.totalSteps,
    required this.status,
  });

  final double percentComplete;
  final int completedSteps;
  final int totalSteps;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 148,
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _GradientRingPainter(progress: percentComplete),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentComplete * 100).toInt()}%',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'complete',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$completedSteps of $totalSteps steps',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            OrchestratorStatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const startAngle = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.onSurfaceVariant.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: const [AppColors.accent, AppColors.accentBright],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => old.progress != progress;
}
