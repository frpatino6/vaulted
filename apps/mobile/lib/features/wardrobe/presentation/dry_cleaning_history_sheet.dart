import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dry_cleaning_model.dart';
import '../domain/dry_cleaning_notifier.dart';

class DryCleaningHistorySheet extends ConsumerWidget {
  const DryCleaningHistorySheet({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DryCleaningModel>> state = ref.watch(dryCleaningNotifierProvider(itemId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: state.when(
            data: (List<DryCleaningModel> records) {
              if (records.isEmpty) {
                return const Center(child: Text('No dry cleaning history yet'));
              }

              final DryCleaningModel? openRecord = _findOpenRecord(records);

              return Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Dry Cleaning History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (openRecord != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await ref
                              .read(dryCleaningNotifierProvider(itemId).notifier)
                              .markReturned(openRecord.id);
                        },
                        child: const Text('Mark as returned'),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemBuilder: (BuildContext context, int index) {
                        final DryCleaningModel record = records[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            record.returnedDate == null
                                ? Icons.local_laundry_service
                                : Icons.check_circle,
                            color: record.returnedDate == null ? Colors.blue : Colors.green,
                          ),
                          title: Text('Sent ${DateFormat.yMMMd().format(record.sentDate)}'),
                          subtitle: Text(
                            record.returnedDate == null
                                ? 'At dry cleaner'
                                : 'Returned ${DateFormat.yMMMd().format(record.returnedDate!)}',
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const Divider(color: Colors.white10),
                      itemCount: records.length,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Unable to load history')),
          ),
        );
      },
    );
  }

  DryCleaningModel? _findOpenRecord(List<DryCleaningModel> records) {
    for (final DryCleaningModel record in records) {
      if (record.returnedDate == null) {
        return record;
      }
    }
    return null;
  }
}
