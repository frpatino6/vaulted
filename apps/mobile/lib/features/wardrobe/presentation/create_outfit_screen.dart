import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../inventory/data/models/item_model.dart';
import '../../household_members/data/models/household_member_model.dart';
import '../../household_members/domain/household_members_notifier.dart';
import '../domain/outfit_notifier.dart';
import '../domain/wardrobe_notifier.dart';
import 'package:vaulted/shared/widgets/help_screen_button.dart';


class CreateOutfitScreen extends ConsumerStatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  ConsumerState<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends ConsumerState<CreateOutfitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();

  final Set<String> _selectedItems = <String>{};
  String? _selectedSeason;
  String? _selectedOwnerMemberId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ItemModel>> wardrobeState = ref.watch(
      wardrobeNotifierProvider,
    );
    final AsyncValue<List<HouseholdMemberModel>> membersState = ref.watch(
      householdMembersNotifierProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: const Text('Create Outfit'),
        actions: [const HelpScreenButton(screenKey: 'wardrobe')],
      ),
      body: wardrobeState.when(
        data: (items) {
          final members = membersState.valueOrNull ?? const <HouseholdMemberModel>[];
          final filteredItems = _selectedOwnerMemberId == null
              ? items
              : items
                  .where((item) =>
                      item.wardrobeAttributes.ownerMemberId == _selectedOwnerMemberId)
                  .toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Outfit name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeason,
                items: const [
                  DropdownMenuItem(
                    value: 'spring_summer',
                    child: Text('Spring / Summer'),
                  ),
                  DropdownMenuItem(
                    value: 'fall_winter',
                    child: Text('Fall / Winter'),
                  ),
                  DropdownMenuItem(
                    value: 'all_season',
                    child: Text('All Season'),
                  ),
                ],
                onChanged:
                    (String? value) => setState(() => _selectedSeason = value),
                decoration: const InputDecoration(labelText: 'Season'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _occasionController,
                decoration: const InputDecoration(labelText: 'Occasion'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedOwnerMemberId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No specific member'),
                  ),
                  ...members.map(
                    (member) => DropdownMenuItem<String>(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedOwnerMemberId = value;
                    _selectedItems.clear();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Household member',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Select items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...filteredItems.map((ItemModel item) {
                final bool selected = _selectedItems.contains(item.id);
                return CheckboxListTile(
                  value: selected,
                  activeColor: AppColors.accent,
                  title: Text(item.name),
                  subtitle: Text(
                    item.wardrobeAttributes.type ?? 'Wardrobe item',
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.add(item.id);
                      } else {
                        _selectedItems.remove(item.id);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _selectedItems.isEmpty ? null : _submit,
                child: const Text('Create outfit'),
              ),
            ],
          );
        },
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (_, _) =>
                const Center(child: Text('Unable to load wardrobe items')),
      ),
    );
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    await ref
        .read(outfitNotifierProvider.notifier)
        .createOutfit(
          name: name,
          description: _descriptionController.text.trim(),
          season: _selectedSeason,
          occasion: _occasionController.text.trim(),
          itemIds: _selectedItems.toList(),
          ownerMemberId: _selectedOwnerMemberId,
        );

    if (!mounted) return;
    context.pop();
  }
}
