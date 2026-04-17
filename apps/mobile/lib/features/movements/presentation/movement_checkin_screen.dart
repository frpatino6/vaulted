import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/movement_model.dart';
import '../domain/movement_detail_notifier.dart';

/// Full-screen QR scanner for checking items back into a movement.
/// Shown as a modal bottom sheet from MovementDetailScreen.
class MovementCheckinScreen extends ConsumerStatefulWidget {
  const MovementCheckinScreen({super.key, required this.movementId});

  final String movementId;

  @override
  ConsumerState<MovementCheckinScreen> createState() =>
      _MovementCheckinScreenState();
}

class _MovementCheckinScreenState extends ConsumerState<MovementCheckinScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _processingQr = false;
  String? _lastScannedName;
  bool _showFeedback = false;
  String? _feedbackError;
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movementDetailNotifierProvider.notifier)
          .load(widget.movementId)
          .whenComplete(() {
            if (!mounted) return;
            setState(() => _initialLoadCompleted = true);
          });
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementDetailNotifierProvider);
    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton ? const AsyncLoading<MovementModel?>() : state;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,
      child: renderState.when(
        data: (movement) {
          if (movement == null) {
            return const Center(
              child: Text(
                'Movement not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return _buildContent(context, movement);
        },
        loading: () => const AppScreenSkeleton(showHeader: false, cardCount: 4),
        error:
            (e, _) => Center(
              child: Text(
                MovementDetailNotifier.message(e),
                style: const TextStyle(color: Colors.white),
              ),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovementModel movement) {
    final pending = movement.items.where((i) => i.status == 'out').toList();
    final returned =
        movement.items.where((i) => i.status == 'returned').toList();
    final total = movement.items.length;
    final allReturned = pending.isEmpty && total > 0;

    return Stack(
      children: [
        // Camera
        if (!allReturned)
          MobileScanner(
            controller: _scanner,
            onDetect: (capture) => _onDetect(capture, movement.id),
          )
        else
          Container(color: AppColors.background),

        // Handle bar
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // Scan overlay (when camera active)
        if (!allReturned) ...[
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _processingQr ? AppColors.accent : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      _processingQr
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                              strokeWidth: 2,
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedOpacity(
                  opacity: _showFeedback ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _feedbackError != null
                              ? AppColors.error.withValues(alpha: 0.9)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _feedbackError != null
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _feedbackError ??
                              '${_lastScannedName ?? 'Item'} checked in',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Scan items to check them in',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Torch button
          Positioned(
            top: AppSpacing.lg + 8,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => _scanner.toggleTorch(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.flashlight_on_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],

        // All done state
        if (allReturned)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'All items checked in!',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Operation is complete.',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Bottom panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomCheckinPanel(
            movement: movement,
            pending: pending,
            returned: returned,
            allReturned: allReturned,
            onClose: () => Navigator.of(context).pop(),
            onComplete: () => _complete(context),
          ),
        ),
      ],
    );
  }

  Future<void> _onDetect(BarcodeCapture capture, String movementId) async {
    if (_processingQr) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'vaulted' || uri.host != 'items') return;

    final itemId = uri.pathSegments.firstOrNull;
    if (itemId == null || itemId.isEmpty) return;

    setState(() {
      _processingQr = true;
      _showFeedback = false;
      _feedbackError = null;
    });

    HapticFeedback.lightImpact();

    try {
      await ref.read(movementDetailNotifierProvider.notifier).checkin(itemId);

      // Find the item name from updated state
      final updated = ref.read(movementDetailNotifierProvider).value;
      final checkedItem = updated?.items.firstWhere(
        (i) => i.itemId == itemId,
        orElse: () => updated!.items.first,
      );

      setState(() {
        _lastScannedName = checkedItem?.itemName;
        _showFeedback = true;
        _feedbackError = null;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _feedbackError = MovementDetailNotifier.message(e);
        _showFeedback = true;
        _lastScannedName = null;
      });
      HapticFeedback.heavyImpact();
    } finally {
      setState(() => _processingQr = false);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _showFeedback = false);
    }
  }

  Future<void> _complete(BuildContext context) async {
    try {
      await ref.read(movementDetailNotifierProvider.notifier).complete();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(MovementDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _BottomCheckinPanel extends StatelessWidget {
  const _BottomCheckinPanel({
    required this.movement,
    required this.pending,
    required this.returned,
    required this.allReturned,
    required this.onClose,
    required this.onComplete,
  });

  final MovementModel movement;
  final List<MovementItemModel> pending;
  final List<MovementItemModel> returned;
  final bool allReturned;
  final VoidCallback onClose;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final total = movement.items.length;
    final returnedCount = returned.length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Check-in',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$returnedCount / $total',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? returnedCount / total : 0,
                    backgroundColor: AppColors.onSurfaceVariant.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Pending items list
          if (pending.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: pending.length,
                itemBuilder:
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _PendingItemChip(item: pending[i]),
                    ),
              ),
            ),
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      side: BorderSide(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save & Close'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          pending.isEmpty
                              ? const Color(0xFF4CAF50)
                              : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      pending.isEmpty
                          ? Icons.check_circle_rounded
                          : Icons.report_problem_outlined,
                      size: 18,
                    ),
                    label: Text(
                      pending.isEmpty
                          ? 'Complete'
                          : 'Complete (${pending.length} missing)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingItemChip extends StatelessWidget {
  const _PendingItemChip({required this.item});

  final MovementItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child:
                item.itemPhoto.isNotEmpty
                    ? Image.network(
                      item.itemPhoto,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                    : _placeholder(),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.itemName,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 48,
    color: AppColors.surfaceVariant,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 20,
      color: AppColors.onSurfaceVariant,
    ),
  );
}
