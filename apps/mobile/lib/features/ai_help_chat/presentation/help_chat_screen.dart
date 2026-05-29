import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/help_message_model.dart';
import '../domain/ai_help_notifier.dart';
import '../domain/ai_help_state.dart';

class HelpChatScreen extends ConsumerStatefulWidget {
  const HelpChatScreen({super.key, this.currentScreen, this.initialQuery});

  final String? currentScreen;
  final String? initialQuery;

  @override
  ConsumerState<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends ConsumerState<HelpChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasSentInitialQuery = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasSentInitialQuery) {
          _hasSentInitialQuery = true;
          _sendText(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendText(String text) {
    final query = text.trim();
    if (query.isEmpty) return;
    _textController.clear();
    ref.read(aiHelpNotifierProvider.notifier).sendMessage(
          query,
          currentScreen: widget.currentScreen,
        );
    _scrollToBottom();
  }

  void _send() => _sendText(_textController.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiHelpNotifierProvider);

    ref.listen<AiHelpState>(aiHelpNotifierProvider, (_, next) {
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
          'Vaulted Guide',
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
                  ref.read(aiHelpNotifierProvider.notifier).clearSession(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyState(
                    currentScreen: widget.currentScreen,
                    onSuggestionTap: _sendText,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return _MessageBubble(
                        message: message,
                        onSuggestionTap: _sendText,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.currentScreen,
    required this.onSuggestionTap,
  });

  final String? currentScreen;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsFor(currentScreen);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 56,
                color: AppColors.accentBright.withValues(alpha: 0.75),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Vaulted Guide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ask me anything about how to use Vaulted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SuggestionsWrap(
                suggestions: suggestions,
                onSuggestionTap: onSuggestionTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _suggestionsFor(String? currentScreen) {
    return switch (currentScreen) {
      'inventory' => [
          'How do I add an item?',
          'How do I scan with AI?',
          'How do I filter items?',
        ],
      'movements' => [
          'How do I loan an item?',
          'How do I mark a return?',
          'What is movement history?',
        ],
      'wardrobe' => [
          'How do I create an outfit?',
          'How do I log dry cleaning?',
          'What is the wardrobe module?',
        ],
      'maintenance' => [
          'How do I schedule maintenance?',
          'What is AI risk scoring?',
          'How do I mark maintenance done?',
        ],
      'insurance' => [
          'How do I add a policy?',
          'What is coverage gap analysis?',
          'How do I draft a claim?',
        ],
      'users' => [
          'How do I invite a user?',
          'What are the different roles?',
          'How do I change a user role?',
        ],
      _ => [
          'What can Vaulted do?',
          'How do I add a property?',
          'How do I invite someone?',
          'What roles exist?',
        ],
    };
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
  });

  final HelpMessageModel message;
  final void Function(String) onSuggestionTap;

  bool get _isUser => message.role == HelpMessageRole.user;

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
                maxWidth: MediaQuery.of(context).size.width * 0.82,
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
                    : _isUser
                        ? Text(
                            message.content,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                          )
                        : MarkdownBody(
                            data: message.content,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(Theme.of(context))
                                    .copyWith(
                              p: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    height: 1.4,
                                  ),
                              listBullet: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    height: 1.4,
                                  ),
                              strong: const TextStyle(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
              ),
            ),
          ),
          if (!_isUser &&
              !message.isLoading &&
              message.suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SuggestionsRow(
              suggestions: message.suggestions,
              onSuggestionTap: onSuggestionTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  const _SuggestionsRow({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _SuggestionChip(
            suggestion: suggestion,
            onTap: () => onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }
}

class _SuggestionsWrap extends StatelessWidget {
  const _SuggestionsWrap({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: suggestions
          .map(
            (suggestion) => _SuggestionChip(
              suggestion: suggestion,
              onTap: () => onSuggestionTap(suggestion),
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final String suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: suggestion,
      child: ActionChip(
        avatar: const Icon(Icons.bolt_outlined, size: 16),
        label: Text(suggestion),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColors.surfaceVariant,
        side: BorderSide(
          color: AppColors.accentBright.withValues(alpha: 0.5),
          width: 0.8,
        ),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.accentBright.withValues(alpha: 0.9),
            ),
      ),
    );
  }
}

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
        children: List.generate(3, (index) {
          final delay = index * 0.2;
          final opacity =
              ((_animation.value + delay) % 1.0).clamp(0.3, 1.0).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Ask how to use Vaulted',
              textField: true,
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                style: const TextStyle(color: AppColors.onBackground),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask how to use Vaulted...',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
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
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedOpacity(
            opacity: isLoading ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Send message',
              color: AppColors.accentBright,
              onPressed: isLoading ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
