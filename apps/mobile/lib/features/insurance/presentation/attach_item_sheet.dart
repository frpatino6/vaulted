import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';
import '../../inventory/data/search_remote_data_source_provider.dart';

typedef OnAttachedCallback = Future<void> Function(
    String itemId, double coveredValue, String currency);

/// Bottom sheet for attaching an inventory item to an insurance policy.
/// Phase 1: search inventory items. Phase 2: enter covered value for selection.
class AttachItemSheet extends ConsumerStatefulWidget {
  const AttachItemSheet({
    super.key,
    required this.policyId,
    required this.onAttached,
  });

  final String policyId;
  final OnAttachedCallback onAttached;

  @override
  ConsumerState<AttachItemSheet> createState() => _AttachItemSheetState();
}

class _AttachItemSheetState extends ConsumerState<AttachItemSheet> {
  final _searchCtrl = TextEditingController();
  final _coveredValueCtrl = TextEditingController();

  List<ItemModel> _results = [];
  ItemModel? _selected;
  String _currency = 'USD';
  bool _searching = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _coveredValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final src = ref.read(searchRemoteDataSourceProvider);
      final items = await src.search(query: query);
      if (mounted) setState(() => _results = items);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    final item = _selected;
    if (item == null) return;

    final coveredValue = double.tryParse(_coveredValueCtrl.text.trim());
    if (coveredValue == null || coveredValue <= 0) {
      setState(() => _error = 'Enter a valid covered value.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.onAttached(item.id, coveredValue, _currency);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            _selected == null ? 'Attach Item' : 'Set Covered Value',
            style: AppTypography.titleLarge
                .copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _selected == null
                ? 'Search your inventory and select an item to insure.'
                : 'How much does this policy cover for this item?',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_selected == null) ...[
            // ── Phase 1: search ───────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              style: TextStyle(color: AppColors.onBackground),
              decoration: InputDecoration(
                hintText: 'Search by name, category, brand…',
                hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.onSurfaceVariant),
                suffixIcon: _searching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent),
                          ),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
              onChanged: (v) => _search(v),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) =>
                      _ItemTile(item: _results[i], onTap: () {
                        setState(() {
                          _selected = _results[i];
                          // Pre-fill covered value with currentValue if available
                          final cv = _results[i].valuation?.currentValue;
                          if (cv != null && cv > 0) {
                            _coveredValueCtrl.text = cv.toString();
                          }
                        });
                      }),
                ),
              )
            else if (!_searching && _searchCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'No items found.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
          ] else ...[
            // ── Phase 2: selected item + covered value ────────────────────
            _SelectedItemCard(
              item: _selected!,
              onClear: () => setState(() {
                _selected = null;
                _coveredValueCtrl.clear();
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _coveredValueCtrl,
                    style: TextStyle(color: AppColors.onBackground),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration('Covered Value'),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    dropdownColor: AppColors.surfaceVariant,
                    style: TextStyle(color: AppColors.onBackground),
                    decoration: _inputDecoration('Currency'),
                    items: ['USD', 'EUR', 'GBP']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'USD'),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black),
                        ),
                      )
                    : const Text('Attach Item',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorStyle: TextStyle(color: AppColors.error),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap});

  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoUrl =
        item.photos.isNotEmpty ? item.photos.first : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    item.subcategory.isNotEmpty
                        ? '${item.category} · ${item.subcategory}'
                        : item.category,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Current value
            if (item.valuation != null &&
                item.valuation!.currentValue > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '\$${_fmtValue(item.valuation!.currentValue)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.surface,
      child: Icon(Icons.inventory_2_outlined,
          size: 22, color: AppColors.onSurfaceVariant),
    );
  }

  String _fmtValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }
}

class _SelectedItemCard extends StatelessWidget {
  const _SelectedItemCard({required this.item, required this.onClear});

  final ItemModel item;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.subcategory.isNotEmpty
                      ? '${item.category} · ${item.subcategory}'
                      : item.category,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
