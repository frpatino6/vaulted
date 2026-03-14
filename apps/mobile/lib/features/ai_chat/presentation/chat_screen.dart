import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/users/domain/current_user_jwt.dart';
import '../../../shared/widgets/room_inventory_asset_card.dart';
import '../data/ai_chat_remote_data_source.dart';
import '../data/models/chat_message_model.dart';
import '../domain/ai_chat_notifier.dart';
import '../domain/ai_chat_state.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;
    _textController.clear();
    ref.read(aiChatNotifierProvider.notifier).sendMessage(query);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatNotifierProvider);
    final role = currentUserRole() ?? 'guest';
    final canSeeValues = role == 'owner' || role == 'auditor';

    ref.listen<AiChatState>(aiChatNotifierProvider, (_, next) {
      if (!next.isLoading) _scrollToBottom();
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        title: Text(
          'AI Assistant',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear session',
              onPressed: () =>
                  ref.read(aiChatNotifierProvider.notifier).clearSession(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      return _MessageBubble(
                        message: msg,
                        canSeeValues: canSeeValues,
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _textController,
            isLoading: state.isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 56,
              color: AppColors.accentBright.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ask about your inventory',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try: "Where is my Rolex?"\nor "List furniture over \$5,000"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.canSeeValues});

  final ChatMessageModel message;
  final bool canSeeValues;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: _isUser
                      ? AppColors.accent.withValues(alpha: 0.9)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(_isUser ? 16 : 4),
                    bottomRight: Radius.circular(_isUser ? 4 : 16),
                  ),
                ),
                child: message.isLoading
                    ? const _LoadingDots()
                    : Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isUser
                                  ? Colors.black87
                                  : AppColors.onBackground,
                              height: 1.4,
                            ),
                      ),
              ),
            ),
          ),
          if (!_isUser && message.items.isNotEmpty && !message.isLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            _ItemsRow(items: message.items, canSeeValues: canSeeValues),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ItemsRow extends StatelessWidget {
  const _ItemsRow({required this.items, required this.canSeeValues});

  final List<ChatItemResult> items;
  final bool canSeeValues;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, idx) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final chatItem = items[index];
          final itemModel = AiChatRemoteDataSource.chatItemToItemModel(chatItem);
          return SizedBox(
            width: 280,
            child: RoomInventoryAssetCard(
              item: itemModel,
              canSeeValues: canSeeValues,
              nameMaxLines: 2,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final opacity = ((_animation.value + delay) % 1.0).clamp(0.3, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              style: const TextStyle(color: AppColors.onBackground),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask about your inventory…',
                hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Mic placeholder
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            color: AppColors.onSurfaceVariant,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice coming soon')),
              );
            },
          ),
          const SizedBox(width: 4),
          AnimatedOpacity(
            opacity: isLoading ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: AppColors.accentBright,
              onPressed: isLoading ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
