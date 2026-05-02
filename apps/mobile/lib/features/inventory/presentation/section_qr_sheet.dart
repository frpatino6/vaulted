import 'dart:math' show max, min;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/room_section_model.dart';

/// Shows all sections in a room with their QR codes and optional photo preview.
void showSectionQrSheet(
  BuildContext context,
  String roomId,
  String roomName,
  List<RoomSectionModel> sections,
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
  final List<RoomSectionModel> sections;

  @override
  State<_SectionQrSheet> createState() => _SectionQrSheetState();
}

class _SectionQrSheetState extends State<_SectionQrSheet> {
  int _selectedIndex = 0;

  String _qrData(RoomSectionModel section) =>
      'vaulted://rooms/${widget.roomId}?section=${Uri.encodeComponent(section.name)}';

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
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = widget.sections[i];
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.photo != null) ...[
                            Icon(
                              Icons.image_outlined,
                              size: 12,
                              color: _selectedIndex == i
                                  ? AppColors.background
                                  : AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedIndex == i
                                  ? AppColors.background
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedIndex == i,
                      selectedColor: AppColors.accent,
                      backgroundColor:
                          AppColors.surfaceVariant.withValues(alpha: 0.4),
                      onSelected: (_) => setState(() => _selectedIndex = i),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // QR + photo
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    _QrCard(
                      section: section,
                      roomName: widget.roomName,
                      qrData: _qrData(section),
                    ),
                    if (section.photo != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SectionPhotoPreview(
                        photoUrl: section.photo!,
                        sectionName: '${section.code} · ${section.name}',
                        boundingBox: section.boundingBox,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPhotoPreview extends StatefulWidget {
  const _SectionPhotoPreview({
    required this.photoUrl,
    required this.sectionName,
    this.boundingBox,
  });

  final String photoUrl;
  final String sectionName;
  final SectionBoundingBox? boundingBox;

  @override
  State<_SectionPhotoPreview> createState() => _SectionPhotoPreviewState();
}

class _SectionPhotoPreviewState extends State<_SectionPhotoPreview> {
  Size? _naturalSize;

  @override
  void initState() {
    super.initState();
    if (widget.boundingBox != null) _loadImageSize();
  }

  @override
  void didUpdateWidget(_SectionPhotoPreview old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl && widget.boundingBox != null) {
      setState(() => _naturalSize = null);
      _loadImageSize();
    }
  }

  void _loadImageSize() {
    NetworkImage(widget.photoUrl)
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() => _naturalSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    const double h = 200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'Location map',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: h,
            child: LayoutBuilder(
              builder: (_, constraints) {
                final w = constraints.maxWidth;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.photoUrl,
                      width: w,
                      height: h,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white24),
                        ),
                      ),
                    ),
                    if (widget.boundingBox != null && _naturalSize != null)
                      _BoundingBoxOverlay(
                        bbox: widget.boundingBox!,
                        naturalSize: _naturalSize!,
                        containerW: w,
                        containerH: h,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 13, color: Color(0xFFC5A059)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                widget.sectionName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BoundingBoxOverlay extends StatelessWidget {
  const _BoundingBoxOverlay({
    required this.bbox,
    required this.naturalSize,
    required this.containerW,
    required this.containerH,
    this.fit = BoxFit.contain,
  });

  final SectionBoundingBox bbox;
  final Size naturalSize;
  final double containerW, containerH;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final double scale;
    if (fit == BoxFit.cover) {
      scale = max(containerW / naturalSize.width, containerH / naturalSize.height);
    } else {
      scale = min(containerW / naturalSize.width, containerH / naturalSize.height);
    }
    final renderedW = naturalSize.width * scale;
    final renderedH = naturalSize.height * scale;
    final offsetX = (containerW - renderedW) / 2;
    final offsetY = (containerH - renderedH) / 2;

    final left = offsetX + bbox.x * renderedW;
    final top = offsetY + bbox.y * renderedH;
    final width = bbox.width * renderedW;
    final height = bbox.height * renderedH;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE53935), width: 2.5),
          color: const Color(0xFFE53935).withValues(alpha: 0.15),
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

  final RoomSectionModel section;
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
                  widget.section.name,
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
