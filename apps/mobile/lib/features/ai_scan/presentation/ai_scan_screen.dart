import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/floor_model.dart';
import '../domain/ai_scan_notifier.dart';
import '../domain/ai_scan_state.dart';

class AiScanScreen extends ConsumerStatefulWidget {
  const AiScanScreen({
    super.key,
    required this.propertyId,
    required this.floors,
  });

  final String propertyId;
  final List<FloorModel> floors;

  @override
  ConsumerState<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends ConsumerState<AiScanScreen> {
  final _picker = ImagePicker();

  List<Map<String, String>> get _propertyRooms => widget.floors
      .expand((f) => f.rooms)
      .map((r) => {'roomId': r.roomId, 'name': r.name, 'type': r.type})
      .toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiScanNotifierProvider);

    ref.listen<AiScanState>(aiScanNotifierProvider, (_, next) {
      if (next is AiScanResultState) {
        context.push(
          '/properties/${widget.propertyId}/ai-scan/review',
          extra: {'result': next.result, 'floors': widget.floors},
        ).then((_) {
          if (mounted) ref.read(aiScanNotifierProvider.notifier).reset();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (state) {
        AiScanCaptureProduct() || AiScanResultState() => _CaptureStep(
            step: 1,
            title: 'Foto del producto',
            subtitle: 'La IA identificará el ítem automáticamente',
            canSkip: false,
            onCapture: _captureProduct,
            onSkip: null,
          ),
        AiScanCaptureInvoice() => _CaptureStep(
            step: 2,
            title: 'Foto de la factura',
            subtitle: 'Extrae precio, fecha y número de serie',
            canSkip: true,
            onCapture: _captureInvoice,
            onSkip: _skipInvoice,
          ),
        AiScanAnalyzing() => const _AnalyzingView(),
        AiScanError(:final message) => _ErrorView(
            message: message,
            onRetry: () =>
                ref.read(aiScanNotifierProvider.notifier).reset(),
          ),
      },
    );
  }

  Future<void> _captureProduct() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    ref.read(aiScanNotifierProvider.notifier).onProductPhotoCaptured(photo);
  }

  Future<void> _captureInvoice() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    await ref
        .read(aiScanNotifierProvider.notifier)
        .onInvoicePhotoCaptured(photo, propertyRooms: _propertyRooms);
  }

  Future<void> _skipInvoice() async {
    await ref
        .read(aiScanNotifierProvider.notifier)
        .skipInvoice(propertyRooms: _propertyRooms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Capture step
// ─────────────────────────────────────────────────────────────────────────────

class _CaptureStep extends StatelessWidget {
  const _CaptureStep({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.canSkip,
    required this.onCapture,
    required this.onSkip,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool canSkip;
  final VoidCallback onCapture;
  final VoidCallback? onSkip;

  static const _tapHint = 'Toca aquí o el botón para fotografiar';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  'PASO $step DE 2',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Step indicator bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: step == 2 ? AppColors.accent : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Viewfinder — tappable
          Expanded(
            child: GestureDetector(
              onTap: onCapture,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: const Color(0xFF0A0A0A)),
                  ..._buildCornerGuides(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        step == 1
                            ? Icons.inventory_2_outlined
                            : Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.white10,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        _tapHint,
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                if (canSkip) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: onSkip,
                    child: const Text(
                      'Saltar este paso  →',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerGuides() => [
        Positioned(
          top: 40, left: 40,
          child: _CornerGuide(top: true, left: true),
        ),
        Positioned(
          top: 40, right: 40,
          child: _CornerGuide(top: true, left: false),
        ),
        Positioned(
          bottom: 40, left: 40,
          child: _CornerGuide(top: false, left: true),
        ),
        Positioned(
          bottom: 40, right: 40,
          child: _CornerGuide(top: false, left: false),
        ),
      ];
}

class _CornerGuide extends StatelessWidget {
  const _CornerGuide({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _CornerPainter(top: top, left: left),
        ),
      );
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = left ? 0.0 : size.width;
    final cy = top ? 0.0 : size.height;
    canvas.drawLine(Offset(cx, cy), Offset(left ? size.width : 0, cy), paint);
    canvas.drawLine(Offset(cx, cy), Offset(cx, top ? size.height : 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) => const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Analizando imágenes...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'La IA está identificando el ítem\ny extrayendo datos de la factura',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'El análisis falló',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Intentar de nuevo'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      );
}
