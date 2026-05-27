import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'qr_print_helper_stub.dart'
    if (dart.library.js_interop) 'qr_print_helper_web.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/item_model.dart';
import '../domain/asset_browser_notifier.dart';


class QrListScreen extends ConsumerWidget {
  const QrListScreen({super.key, this.items});

  /// When provided (e.g. from Wardrobe), these items are displayed directly.
  /// When null, the screen reads from [assetBrowserNotifierProvider].
  final List<ItemModel>? items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final List<ItemModel> displayItems;
    final bool isLoading;
    final bool isFiltered;

    if (items != null) {
      displayItems =
          items!.where((i) => i.qrCode != null && i.qrCode!.isNotEmpty).toList();
      isLoading = false;
      isFiltered = false;
    } else {
      final browserState = ref.watch(assetBrowserNotifierProvider);
      displayItems = browserState.valueOrNull?.items
              .where((i) => i.qrCode != null && i.qrCode!.isNotEmpty)
              .toList() ??
          [];
      isLoading = browserState.isLoading;
      isFiltered = browserState.valueOrNull?.isFiltered ?? false;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundElevated,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.onBackground,
        toolbarHeight: 64,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Codes',
              style:
                  AppTypography.titleSerif.copyWith(color: AppColors.onBackground),
            ),
            if (displayItems.isNotEmpty)
              Text(
                '${displayItems.length} item${displayItems.length == 1 ? '' : 's'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            color: AppColors.accent,
            onPressed: displayItems.isEmpty
                ? null
                : () => _onPrint(context, displayItems),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : displayItems.isEmpty
              ? _EmptyState(isFiltered: isFiltered)
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md + bottomPadding,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) =>
                      _QrCard(item: displayItems[index]),
                ),
    );
  }

  void _onPrint(BuildContext context, List<ItemModel> items) {
    if (kIsWeb) {
      printQrItems(items);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Open the web app in a browser to print QR codes.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.item});

  final ItemModel item;

  void _showFullQr(BuildContext context) {
    final qrCode = item.qrCode!;
    final base64Str = qrCode.contains(',') ? qrCode.split(',').last : qrCode;
    final Uint8List bytes = base64Decode(base64Str);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.lightOnBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.propertyName != null || item.roomName != null) ...[
                const SizedBox(height: 4),
                Text(
                  [item.propertyName, item.roomName]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' › '),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Image.memory(bytes, width: 220, height: 220),
              const SizedBox(height: 8),
              Text(
                'Scan to identify this item',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Close',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrCode = item.qrCode!;
    final base64Str = qrCode.contains(',') ? qrCode.split(',').last : qrCode;
    final Uint8List qrBytes = base64Decode(base64Str);
    final locationText = [item.propertyName, item.roomName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' › ');

    return GestureDetector(
      onTap: () => _showFullQr(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.memory(qrBytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onBackground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (locationText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                locationText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 52,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isFiltered ? 'No QR codes match the current filters' : 'No QR codes yet',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Go back and adjust the filters to see QR codes.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
