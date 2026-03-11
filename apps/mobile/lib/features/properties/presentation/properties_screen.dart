import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/property_model.dart';
import '../domain/properties_notifier.dart';
import 'add_property_sheet.dart';

/// Premium catalog of properties: large image cards, Serif header, outlined FAB.
class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _PropertiesHeader(),
          ),
          asyncState.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(onAddProperty: () => _showAddSheet(context, ref)),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl + 56),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _LuxuryPropertyCard(property: list[index]),
                    ),
                    childCount: list.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorState(
                message: PropertiesNotifier.message(err),
                isMfaRequired: PropertiesNotifier.message(err).toLowerCase().contains('mfa'),
                onRetry: () => ref.read(propertiesNotifierProvider.notifier).load(),
                onMfa: () => context.go('/mfa'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 24),
        child: _LuxuryFab(onPressed: () => _showAddSheet(context, ref)),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddPropertySheet(),
    ).then((created) {
      if (created == true) {
        ref.read(propertiesNotifierProvider.notifier).load();
      }
    });
  }
}

/// Header: back button + 'Properties' in Serif (Playfair Display).
class _PropertiesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppColors.onBackground,
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Properties',
              style: AppTypography.displaySerif.copyWith(color: AppColors.onBackground),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large catalog card: 220 height, full-width image, dark gradient, title + location in white.
class _LuxuryPropertyCard extends StatelessWidget {
  const _LuxuryPropertyCard({required this.property});

  final PropertyModel property;

  String get _location => '${property.address.city}, ${property.address.state}';

  @override
  Widget build(BuildContext context) {
    final hasImage = property.photos.isNotEmpty;
    final imageUrl = hasImage ? property.photos.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/properties/${property.id}'),
          splashColor: Colors.white10,
          highlightColor: Colors.white10.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.35, 0.7, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        property.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A32),
            Color(0xFF15151A),
          ],
        ),
      ),
    );
  }
}

/// Small circular FAB with gold outline and + icon.
class _LuxuryFab extends StatelessWidget {
  const _LuxuryFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background.withOpacity(0.85),
            border: Border.all(
              color: AppColors.accent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: AppColors.accent,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Empty state: thin-stroke icon + premium copy.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddProperty});

  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: AppColors.onSurfaceVariant.withOpacity(0.35),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Add your first luxury property',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground.withOpacity(0.85),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a property to start organizing floors, rooms and items.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onAddProperty,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add property'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.isMfaRequired,
    required this.onRetry,
    required this.onMfa,
  });

  final String message;
  final bool isMfaRequired;
  final VoidCallback onRetry;
  final VoidCallback onMfa;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isMfaRequired
                  ? 'MFA verification required to access properties.'
                  : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isMfaRequired)
              FilledButton(
                onPressed: onMfa,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Complete MFA'),
              )
            else
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
