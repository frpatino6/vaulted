import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isHandlingDetection = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingDetection || !mounted) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || !value.startsWith('vaulted://items/')) {
        continue;
      }

      final uri = Uri.tryParse(value);
      final segments = uri?.pathSegments ?? const <String>[];
      final itemId = segments.isNotEmpty ? segments.last : '';
      if (itemId.isEmpty) {
        continue;
      }

      _isHandlingDetection = true;
      context.pushReplacement('/items/$itemId');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Item'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: const _ScannerOverlayPainter(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Point camera at item QR code',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
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

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 4;
    const double bracketLength = 24;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      const Offset(0, bracketLength),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(bracketLength, 0),
      paint,
    );

    canvas.drawLine(
      Offset(size.width - bracketLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, bracketLength),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height - bracketLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(bracketLength, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width - bracketLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - bracketLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
