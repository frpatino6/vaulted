---
name: first-load-skeleton-rule
description: Mandatory project rule — all AsyncNotifier screens must show skeleton on initial frame, never empty state
metadata:
  type: feedback
---

# First-Load Skeleton Rule (Mandatory)

**Rule:** If a screen uses `AsyncNotifier` with `load()` in `postFrame`, never show empty/not-found/error states on the first frame while data is loading. Always show a skeleton.

**Why:** Premium UX. Shows the user that work is happening, not that nothing exists.

## Implementation Pattern

```dart
class _MyScreenState extends ConsumerState<MyScreen> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myNotifierProvider.notifier).load(id)
          .whenComplete(() {
            if (!mounted) return;
            setState(() => _initialLoadCompleted = true);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myNotifierProvider);
    final showInitialSkeleton = 
        !_initialLoadCompleted && 
        !state.hasError && 
        (state.isLoading || state.valueOrNull == null);
    
    final renderState = showInitialSkeleton 
        ? const AsyncLoading<MyModel?>() 
        : state;

    return renderState.when(
      loading: () => const AppScreenSkeleton(showHeader: false, cardCount: 5),
      error: (err, _) => _ErrorView(...),
      data: (model) {
        if (model == null) return _NotFoundView();
        return _Content(model: model);
      },
    );
  }
}
```

## Key Points
1. Flag `_initialLoadCompleted` tracks whether first fetch has completed
2. On first frame: `showInitialSkeleton = true` → renders skeleton
3. After first load finishes: `showInitialSkeleton = false` → renders real state (data/error/not-found)
4. Empty/not-found only shown **after** first load is done

## Example: Property Detail Screen
- **File:** `property_detail_screen.dart`
- **Status:** ✓ CORRECT
  - Lines 45-46: Flag initialized
  - Lines 50-58: postFrame loads and sets flag
  - Lines 76-81: showInitialSkeleton computed correctly
  - Line 137: Skeleton shown during load
  - This screen passes the rule.

