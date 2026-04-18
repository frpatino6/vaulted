import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/outfit_model.dart';
import '../data/outfit_repository_provider.dart';

class OutfitDetailScreen extends ConsumerWidget {
  const OutfitDetailScreen({super.key, required this.outfitId});

  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<OutfitModel>(
      future: ref.read(outfitRepositoryProvider).getOutfitById(outfitId),
      builder: (BuildContext context, AsyncSnapshot<OutfitModel> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: AppScreenSkeleton(showHeader: false));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Unable to load outfit')),
          );
        }
        final OutfitModel outfit = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            title: Text(outfit.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outfit.description != null &&
                    outfit.description!.isNotEmpty)
                  Text(
                    outfit.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      final OutfitItemPreviewModel item =
                          outfit.items.isNotEmpty
                              ? outfit.items[index]
                              : OutfitItemPreviewModel(
                                id: outfit.itemIds[index],
                                name: 'Wardrobe Item',
                              );
                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 88,
                                width: double.infinity,
                                child:
                                    item.photo == null
                                        ? const ColoredBox(
                                          color: AppColors.background,
                                          child: Icon(Icons.checkroom),
                                        )
                                        : CachedNetworkImage(
                                          imageUrl: item.photo!,
                                          fit: BoxFit.cover,
                                          errorWidget:
                                              (_, _, _) => const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                    () => context.push('/items/${item.id}'),
                                child: const Text('View item'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder:
                        (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemCount:
                        outfit.items.isNotEmpty
                            ? outfit.items.length
                            : outfit.itemIds.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
