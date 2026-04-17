import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/outfit_model.dart';
import '../domain/outfit_notifier.dart';

class OutfitListScreen extends ConsumerWidget {
  const OutfitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OutfitModel>> state = ref.watch(
      outfitNotifierProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: const Text('Outfits'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/wardrobe/outfits/new'),
        label: const Text('Create Outfit'),
        icon: const Icon(Icons.add),
      ),
      body: state.when(
        data: (List<OutfitModel> outfits) {
          if (outfits.isEmpty) {
            return const Center(child: Text('No outfits yet'));
          }

          return RefreshIndicator(
            onRefresh:
                () => ref.read(outfitNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final OutfitModel outfit = outfits[index];
                final List<String> thumbnails =
                    outfit.items
                        .map((OutfitItemPreviewModel item) => item.photo)
                        .whereType<String>()
                        .take(3)
                        .toList();
                return InkWell(
                  onTap: () => context.push('/wardrobe/outfits/${outfit.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outfit.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.onBackground),
                        ),
                        if (outfit.description != null &&
                            outfit.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            outfit.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: List<Widget>.generate(3, (
                              int thumbIndex,
                            ) {
                              final String? image =
                                  thumbIndex < thumbnails.length
                                      ? thumbnails[thumbIndex]
                                      : null;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: AppColors.background,
                                    child:
                                        image == null
                                            ? const Icon(
                                              Icons.checkroom,
                                              color: AppColors.onSurfaceVariant,
                                            )
                                            : CachedNetworkImage(
                                              imageUrl: image,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (_, __, ___) => const Icon(
                                                    Icons.broken_image_outlined,
                                                    color:
                                                        AppColors
                                                            .onSurfaceVariant,
                                                  ),
                                            ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemCount: outfits.length,
            ),
          );
        },
        loading: () => const AppScreenSkeleton(showHeader: false),
        error: (_, __) => const Center(child: Text('Unable to load outfits')),
      ),
    );
  }
}
