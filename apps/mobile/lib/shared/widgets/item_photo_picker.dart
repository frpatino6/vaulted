import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';

/// Reusable photo picker strip for AddItemSheet, EditItemSheet, and ItemDetailScreen.
/// Shows existing CDN URLs, pending XFiles, and an "Add photo" button (max 10 total).
class ItemPhotoPicker extends StatelessWidget {
  const ItemPhotoPicker({
    super.key,
    required this.photos,
    required this.pendingFiles,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemoveExisting,
    required this.onRemovePending,
    this.uploading = false,
  });

  final List<String> photos;
  final List<XFile> pendingFiles;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final void Function(int index) onRemoveExisting;
  final void Function(int index) onRemovePending;
  final bool uploading;

  static const double _thumbHeight = 100;
  static const double _thumbWidth = 90;
  static const int _maxPhotos = 10;

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add photo',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                title: Text(
                  'Camera',
                  style: const TextStyle(color: AppColors.onBackground),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onPickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text(
                  'Gallery',
                  style: const TextStyle(color: AppColors.onBackground),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onPickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = photos.length + pendingFiles.length;
    final canAddMore = totalCount < _maxPhotos;

    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < photos.length; i++) _buildExistingThumb(context, i),
              for (var i = 0; i < pendingFiles.length; i++) _buildPendingThumb(context, i),
              if (canAddMore) _buildAddPhotoButton(context),
            ],
          ),
        ),
        if (uploading)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingThumb(BuildContext context, int index) {
    final url = photos[index];
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        height: _thumbHeight,
        width: _thumbWidth,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => _placeholderBox(context),
                errorWidget: (_, _, _) => _placeholderBox(context),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _removeButton(() => onRemoveExisting(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingThumb(BuildContext context, int index) {
    final file = pendingFiles[index];
    final path = file.path;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        height: _thumbHeight,
        width: _thumbWidth,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: path.isNotEmpty && File(path).existsSync()
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                      )
                    : _placeholderBox(context),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _removeButton(() => onRemovePending(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        height: _thumbHeight,
        width: _thumbWidth,
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(AppSpacing.sm),
          color: AppColors.accent.withValues(alpha: 0.8),
          strokeWidth: 2,
          dashPattern: const [6, 4],
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPickerOptions(context),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 32,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderBox(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
