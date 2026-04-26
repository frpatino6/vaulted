import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../household_members/data/models/household_member_model.dart';

class WardrobeFiltersResult {
  const WardrobeFiltersResult({
    required this.memberId,
    required this.season,
    required this.cleaningStatus,
  });

  final String? memberId;
  final String season;
  final String cleaningStatus;
}

class WardrobeFiltersSheet extends StatefulWidget {
  const WardrobeFiltersSheet({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.selectedSeason,
    required this.selectedCleaningStatus,
  });

  final List<HouseholdMemberModel> members;
  final String? selectedMemberId;
  final String selectedSeason;
  final String selectedCleaningStatus;

  @override
  State<WardrobeFiltersSheet> createState() => _WardrobeFiltersSheetState();
}

class _WardrobeFiltersSheetState extends State<WardrobeFiltersSheet> {
  late String? _memberId;
  late String _season;
  late String _cleaningStatus;

  @override
  void initState() {
    super.initState();
    _memberId = widget.selectedMemberId;
    _season = widget.selectedSeason;
    _cleaningStatus = widget.selectedCleaningStatus;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.76,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF181818),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ModalHandle(),
            _Header(onClear: _clearAll),
            const Divider(color: Colors.white10, height: 1, thickness: 0.5),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: 'MEMBER',
                      options: [
                        const _FilterOption(label: 'Everyone', value: null),
                        ...widget.members.map(
                          (HouseholdMemberModel m) =>
                              _FilterOption(label: m.name, value: m.id),
                        ),
                      ],
                      selectedValue: _memberId,
                      onSelected: (String? v) =>
                          setState(() => _memberId = v),
                    ),
                    _FilterSection(
                      title: 'SEASON',
                      options: const [
                        _FilterOption(label: 'All Seasons', value: 'all'),
                        _FilterOption(
                            label: 'Spring / Summer', value: 'spring_summer'),
                        _FilterOption(
                            label: 'Fall / Winter', value: 'fall_winter'),
                        _FilterOption(label: 'All Season', value: 'all_season'),
                      ],
                      selectedValue: _season,
                      onSelected: (String? v) =>
                          setState(() => _season = v ?? 'all'),
                    ),
                    _FilterSection(
                      title: 'CONDITION',
                      options: const [
                        _FilterOption(label: 'All', value: 'all'),
                        _FilterOption(label: 'Clean', value: 'clean'),
                        _FilterOption(
                            label: 'Needs Cleaning', value: 'needs_cleaning'),
                        _FilterOption(
                            label: 'At Dry Cleaner',
                            value: 'at_dry_cleaner'),
                      ],
                      selectedValue: _cleaningStatus,
                      onSelected: (String? v) =>
                          setState(() => _cleaningStatus = v ?? 'all'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _ApplyButton(
              onPressed: () => Navigator.of(context).pop(
                WardrobeFiltersResult(
                  memberId: _memberId,
                  season: _season,
                  cleaningStatus: _cleaningStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _memberId = null;
      _season = 'all';
      _cleaningStatus = 'all';
    });
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ModalHandle extends StatelessWidget {
  const _ModalHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A8A8A),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Clear All'),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Filters',
                style: AppTypography.displaySerif.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.4,
              ),
            ),
            child: const Text('Show Results'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter section + chip
// ---------------------------------------------------------------------------

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final String? value;
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<_FilterOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF787878),
                  letterSpacing: 2.0,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options
              .map(
                (_FilterOption opt) => _FilterChip(
                  label: opt.label,
                  isSelected: selectedValue == opt.value,
                  onTap: () => onSelected(opt.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFF383838),
            width: isSelected ? 1.0 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.68),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
        ),
      ),
    );
  }
}
