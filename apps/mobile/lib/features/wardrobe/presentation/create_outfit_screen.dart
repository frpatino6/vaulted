import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';
import '../domain/outfit_notifier.dart';
import '../domain/wardrobe_notifier.dart';

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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ItemModel>> wardrobeState = ref.watch(wardrobeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: const Text('Create Outfit'),
      ),
      body: wardrobeState.when(
        data: (items) {
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
                  DropdownMenuItem(value: 'spring_summer', child: Text('Spring / Summer')),
                  DropdownMenuItem(value: 'fall_winter', child: Text('Fall / Winter')),
                  DropdownMenuItem(value: 'all_season', child: Text('All Season')),
                ],
                onChanged: (String? value) => setState(() => _selectedSeason = value),
                decoration: const InputDecoration(labelText: 'Season'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _occasionController,
                decoration: const InputDecoration(labelText: 'Occasion'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Select items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((ItemModel item) {
                final bool selected = _selectedItems.contains(item.id);
                return CheckboxListTile(
                  value: selected,
                  activeColor: AppColors.accent,
                  title: Text(item.name),
                  subtitle: Text(item.wardrobeAttributes.type ?? 'Wardrobe item'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load wardrobe items')),
      ),
    );
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    await ref.read(outfitNotifierProvider.notifier).createOutfit(
          name: name,
          description: _descriptionController.text.trim(),
          season: _selectedSeason,
          occasion: _occasionController.text.trim(),
          itemIds: _selectedItems.toList(),
        );

    if (!mounted) return;
    context.pop();
  }
}
