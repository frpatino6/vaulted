import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/movement_model.dart';
import '../domain/active_movement_notifier.dart';

/// Full-screen QR scanner for building a movement's item list.
/// Every scanned item is immediately persisted to the backend.
class MovementScanScreen extends ConsumerStatefulWidget {
  const MovementScanScreen({super.key, required this.movementId});

  final String movementId;

  @override
  ConsumerState<MovementScanScreen> createState() => _MovementScanScreenState();
}

class _MovementScanScreenState extends ConsumerState<MovementScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  bool _processingQr = false;
  String? _lastScannedName;
  bool _showFeedback = false;
  String? _feedbackError;

  @override
  void dispose() {
    _scanner.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movementAsync = ref.watch(activeMovementNotifierProvider);

    return movementAsync.when(
      data: (drafts) {
        final movement = drafts.cast<MovementModel?>().firstWhere(
          (m) => m?.id == widget.movementId,
          orElse: () => null,
        );
        if (movement == null) {
          // Draft was activated/cancelled — leave the scan screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return const SizedBox.shrink();
        }
        return _buildScanner(context, movement);
      },
      loading:
          () => Scaffold(
            backgroundColor: Colors.black,
            body: const AppScreenSkeleton(showHeader: false, cardCount: 4),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                ActiveMovementNotifier.message(e),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
    );
  }

  Widget _buildScanner(BuildContext context, MovementModel movement) {
    final typeInfo = _movementTypeInfo(movement.operationType);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _scanner,
            onDetect: (capture) => _onDetect(capture, movement.id),
          ),

          // Scan overlay
          _ScanOverlay(
            processingQr: _processingQr,
            showFeedback: _showFeedback,
            feedbackName: _lastScannedName,
            feedbackError: _feedbackError,
          ),

          // Floating counter — positioned below the top bar, always above
          // the bottom panel regardless of its expanded/collapsed state.
          // minChildSize: 0.12 → ~100px; initialChildSize: 0.28 → ~240px.
          // Using bottom: 260 keeps it above the panel in all snap states.
          Positioned(
            left: 0,
            right: 0,
            bottom: 260,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: movement.items.isEmpty ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${movement.items.length} item${movement.items.length == 1 ? '' : 's'} scanned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Cancel
                  _GlassButton(
                    icon: Icons.close,
                    onTap: () => _confirmCancel(context, movement),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Movement info
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(typeInfo.icon, color: typeInfo.color, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              movement.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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
                  const SizedBox(width: AppSpacing.sm),
                  // Torch
                  _GlassButton(
                    icon: Icons.flashlight_on_outlined,
                    onTap: () => _scanner.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom draggable panel
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.12, 0.28, 0.65],
            builder:
                (ctx, scrollCtrl) => _BottomPanel(
                  movement: movement,
                  scrollController: scrollCtrl,
                  onRemove: (itemId) => _removeItem(movement.id, itemId),
                  onActivate: () => _activate(context, movement),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture, String movementId) async {
    if (_processingQr) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // Parse vaulted://items/{id}
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
      final movement = await ref
          .read(activeMovementNotifierProvider.notifier)
          .addItem(movementId, itemId);

      final addedItem = movement.items.lastWhere(
        (i) => i.itemId == itemId,
        orElse: () => movement.items.last,
      );

      setState(() {
        _lastScannedName = addedItem.itemName;
        _showFeedback = true;
        _feedbackError = null;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      final message = ActiveMovementNotifier.message(e);
      final normalized = message.toLowerCase();
      final isDuplicate =
          normalized.contains('already') || normalized.contains('conflict');
      setState(() {
        _feedbackError = isDuplicate ? 'Already scanned' : message;
        _showFeedback = true;
        _lastScannedName = null;
      });
      HapticFeedback.heavyImpact();
    } finally {
      setState(() => _processingQr = false);

      // Auto-hide feedback after 2s
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _showFeedback = false);
    }
  }

  Future<void> _removeItem(String movementId, String itemId) async {
    try {
      await ref
          .read(activeMovementNotifierProvider.notifier)
          .removeItem(movementId, itemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ActiveMovementNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _activate(BuildContext context, MovementModel movement) async {
    if (movement.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan at least one item before activating'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }

    final isDisposal = movement.operationType == 'disposal';
    final isTransfer = movement.operationType == 'transfer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceVariant,
            title: Text(
              isDisposal ? 'Confirm Disposal' : 'Confirm Operation',
              style: TextStyle(color: AppColors.onBackground),
            ),
            content: Text(
              isDisposal
                  ? '${movement.items.length} item(s) will be marked as disposed. This cannot be undone.'
                  : isTransfer
                  ? '${movement.items.length} item(s) will be moved to ${movement.destinationPropertyName.isNotEmpty ? movement.destinationPropertyName : 'destination'}. Location will update immediately.'
                  : 'Activate "${movement.title}" with ${movement.items.length} item(s)?',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDisposal ? AppColors.error : AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  isDisposal
                      ? 'Dispose'
                      : isTransfer
                      ? 'Transfer'
                      : 'Activate',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final activated = await ref
          .read(activeMovementNotifierProvider.notifier)
          .activate(movement.id);

      if (mounted) {
        context.go('/movements/${activated.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ActiveMovementNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, MovementModel movement) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceVariant,
            title: Text(
              'Cancel operation?',
              style: TextStyle(color: AppColors.onBackground),
            ),
            content: Text(
              'The draft will be saved. You can resume it later from the Operations screen.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Keep scanning',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: Text(
                  'Save & exit',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay
// ---------------------------------------------------------------------------

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({
    required this.processingQr,
    required this.showFeedback,
    this.feedbackName,
    this.feedbackError,
  });

  final bool processingQr;
  final bool showFeedback;
  final String? feedbackName;
  final String? feedbackError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan frame
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    processingQr
                        ? AppColors.accent
                        : (showFeedback && feedbackError == null)
                        ? const Color(0xFF4CAF50)
                        : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                processingQr
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Feedback toast
          AnimatedOpacity(
            opacity: showFeedback ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color:
                    feedbackError != null
                        ? AppColors.error.withValues(alpha: 0.9)
                        : const Color(0xFF4CAF50).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feedbackError != null
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    feedbackError ?? '${feedbackName ?? 'Item'} added',
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
            'Point camera at an item QR code',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Panel
// ---------------------------------------------------------------------------

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.movement,
    required this.scrollController,
    required this.onRemove,
    required this.onActivate,
  });

  final MovementModel movement;
  final ScrollController scrollController;
  final void Function(String itemId) onRemove;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final items = movement.items;
    final isDisposal = movement.operationType == 'disposal';
    final isTransfer = movement.operationType == 'transfer';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              12,
              AppSpacing.md,
              0,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '${items.length} item${items.length == 1 ? '' : 's'} scanned',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: items.isEmpty ? null : onActivate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDisposal
                                  ? AppColors.error
                                  : isTransfer
                                  ? const Color(0xFF2196F3)
                                  : AppColors.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                        ),
                        icon: Icon(
                          isDisposal
                              ? Icons.delete_outline_rounded
                              : isTransfer
                              ? Icons.swap_horiz_rounded
                              : Icons.check_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isDisposal
                              ? 'Dispose'
                              : isTransfer
                              ? 'Transfer'
                              : 'Activate',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Colors.white12),
          // Items list
          Expanded(
            child:
                items.isEmpty
                    ? Center(
                      child: Text(
                        'Scan items to add them here',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item =
                            items[items.length - 1 - i]; // newest first
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) {
                            final slideAnimation = Tween<Offset>(
                              begin: const Offset(0, -0.2),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slideAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: _ScannedItemRow(
                            key: ValueKey(item.itemId),
                            item: item,
                            onRemove: () => onRemove(item.itemId),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _ScannedItemRow extends StatelessWidget {
  const _ScannedItemRow({
    super.key,
    required this.item,
    required this.onRemove,
  });

  final MovementItemModel item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                item.itemPhoto.isNotEmpty
                    ? Image.network(
                      item.itemPhoto,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                    : _placeholder(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.fromRoomName.isNotEmpty)
                  Text(
                    '${item.fromPropertyName.isNotEmpty ? '${item.fromPropertyName} · ' : ''}${item.fromRoomName}',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.inventory_2_outlined,
      size: 18,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

// ---------------------------------------------------------------------------

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// Helper re-exported to avoid import of movements_screen in scan screen
_MovementTypeInfo _movementTypeInfo(String type) {
  return switch (type) {
    'loan' => const _MovementTypeInfo(
      Icons.person_outline_rounded,
      Color(0xFF9C27B0),
    ),
    'repair' => const _MovementTypeInfo(
      Icons.build_outlined,
      Color(0xFFFF9800),
    ),
    'disposal' => const _MovementTypeInfo(
      Icons.delete_outline_rounded,
      Color(0xFFCF6679),
    ),
    _ => const _MovementTypeInfo(Icons.swap_horiz_rounded, Color(0xFF2196F3)),
  };
}

class _MovementTypeInfo {
  const _MovementTypeInfo(this.icon, this.color);
  final IconData icon;
  final Color color;
}
