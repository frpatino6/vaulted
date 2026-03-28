import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// Shows all unique sections in a room with their printable QR codes.
void showSectionQrSheet(
  BuildContext context,
  String roomId,
  String roomName,
  List<String> sections,
) {
  if (sections.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No sections defined in this room yet.')),
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SectionQrSheet(
      roomId: roomId,
      roomName: roomName,
      sections: sections,
    ),
  );
}

class _SectionQrSheet extends StatefulWidget {
  const _SectionQrSheet({
    required this.roomId,
    required this.roomName,
    required this.sections,
  });

  final String roomId;
  final String roomName;
  final List<String> sections;

  @override
  State<_SectionQrSheet> createState() => _SectionQrSheetState();
}

class _SectionQrSheetState extends State<_SectionQrSheet> {
  int _selectedIndex = 0;

  String _qrData(String section) =>
      'vaulted://rooms/${widget.roomId}?section=${Uri.encodeComponent(section)}';

  @override
  Widget build(BuildContext context) {
    final section = widget.sections[_selectedIndex];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section QR Codes',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.roomName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Section selector chips
            if (widget.sections.length > 1) ...[
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: widget.sections.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChip(
                    label: Text(
                      widget.sections[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: _selectedIndex == i
                            ? AppColors.background
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    selected: _selectedIndex == i,
                    selectedColor: AppColors.accent,
                    backgroundColor:
                        AppColors.surfaceVariant.withValues(alpha: 0.4),
                    onSelected: (_) =>
                        setState(() => _selectedIndex = i),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // QR display
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _QrCard(
                  section: section,
                  roomName: widget.roomName,
                  qrData: _qrData(section),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatefulWidget {
  const _QrCard({
    required this.section,
    required this.roomName,
    required this.qrData,
  });

  final String section;
  final String roomName;
  final String qrData;

  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard> {
  final _repaintKey = GlobalKey();
  bool _copying = false;

  Future<void> _copyQr() async {
    setState(() => _copying = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null && mounted) {
        await Clipboard.setData(
          ClipboardData(text: widget.qrData),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR link copied to clipboard')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                QrImageView(
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.section,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Print and place this QR in the physical section.\nStaff can scan it to see all items here.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copying ? null : _copyQr,
            icon: _copying
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: const Text('Copy QR link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
