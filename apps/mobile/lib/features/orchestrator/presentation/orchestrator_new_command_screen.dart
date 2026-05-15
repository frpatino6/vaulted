import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../domain/orchestrator_parse_notifier.dart';

class OrchestratorNewCommandScreen extends ConsumerStatefulWidget {
  const OrchestratorNewCommandScreen({super.key});

  @override
  ConsumerState<OrchestratorNewCommandScreen> createState() =>
      _OrchestratorNewCommandScreenState();
}

class _OrchestratorNewCommandScreenState
    extends ConsumerState<OrchestratorNewCommandScreen> {
  final _commandController = TextEditingController();
  String? _selectedPropertyId;
  DateTime? _targetDate;
  bool _generating = false;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available on this device')),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _commandController.text = result.recognizedWords;
            _commandController.selection = TextSelection.fromPosition(
              TextPosition(offset: _commandController.text.length),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you need done.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final parsed = await ref
          .read(orchestratorParseNotifierProvider.notifier)
          .parse(
            command: command,
            propertyId: _selectedPropertyId,
            targetDate: _targetDate?.toIso8601String(),
          );
      if (!mounted) return;
      if (parsed == null) {
        final err = ref.read(orchestratorParseNotifierProvider).error;
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(OrchestratorParseNotifier.errorMessage(err)),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      context.push('/orchestrator/review', extra: parsed);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.background,
            surface: AppColors.surfaceVariant,
            onSurface: AppColors.onBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Widget _buildMicIcon() {
    if (!_speechAvailable) {
      return const Icon(Icons.mic_off, color: AppColors.onSurfaceVariant);
    }
    if (_isListening) {
      return const Icon(Icons.mic, color: Colors.red);
    }
    return const Icon(Icons.mic_outlined, color: AppColors.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesNotifierProvider);
    final properties = propertiesState.valueOrNull ?? <PropertyModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        title: const Text(
          'New Plan',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction text
                const Text(
                  'Describe what you need done',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Command text field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: _isListening
                        ? Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: TextField(
                    controller: _commandController,
                    maxLines: 5,
                    minLines: 4,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "Prepare the dining room for a formal dinner for 8 this Saturday"',
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.xs,
                          top: AppSpacing.xs,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: _isListening
                              ? BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: IconButton(
                            icon: _buildMicIcon(),
                            tooltip: _isListening
                                ? 'Tap to stop'
                                : 'Tap to speak',
                            onPressed: _toggleListening,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isListening) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 8,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Listening…',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Options section
                const Text(
                  'OPTIONS',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Property scope dropdown
                DropdownButtonFormField<String>(
                  value: _selectedPropertyId,
                  dropdownColor: AppColors.surfaceVariant,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Property scope (optional)',
                    labelStyle: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.home_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All properties'),
                    ),
                    ...properties.map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedPropertyId = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Target date picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target date (optional)',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _targetDate != null
                                    ? DateFormat('EEEE, MMM d yyyy')
                                        .format(_targetDate!)
                                    : 'Not set',
                                style: const TextStyle(
                                  color: AppColors.onBackground,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_targetDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _targetDate = null),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.onSurfaceVariant,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Example commands hint
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Example commands',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...[
                        'Prepare the dining room for a formal dinner for 8',
                        'Pack for the Aspen trip next week',
                        'Move the wine collection from the basement',
                        'Inspect the living room before the visit',
                      ].map(
                        (hint) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () {
                              _commandController.text = hint;
                              setState(() {});
                            },
                            child: Text(
                              '• $hint',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Generate button — fixed at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_generating ? 'Generating…' : 'Generate Plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
