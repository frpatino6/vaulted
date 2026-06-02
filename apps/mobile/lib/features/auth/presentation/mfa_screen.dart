import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/auth_token_store.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository_provider.dart';
import '../domain/auth_state.dart';
import 'auth_notifier.dart';

class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({super.key});

  @override
  ConsumerState<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends ConsumerState<MfaScreen> {
  final _codeController = TextEditingController();
  String? _error;
  String? _setupSecret;
  Uint8List? _setupQrBytes;
  String? _setupError;
  bool _setupLoading = false;
  bool _setupLoadStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthTokenStore.instance.isMfaSetupRequired) {
        _loadMfaSetup();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadMfaSetup() async {
    if (_setupLoadStarted) return;
    setState(() {
      _setupLoadStarted = true;
      _setupLoading = true;
      _setupError = null;
    });

    try {
      final setup = await ref.read(authRepositoryProvider).setupMfa();
      final qrCode = setup['qrCode'] as String?;
      if (!mounted) return;
      setState(() {
        _setupSecret = setup['secret'] as String?;
        _setupQrBytes = _decodeDataUrl(qrCode);
        _setupLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setupError = 'Could not start MFA setup. Log in again and retry.';
        _setupLoading = false;
      });
    }
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final comma = value.indexOf(',');
    final payload = comma == -1 ? value : value.substring(comma + 1);
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  void _verify() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a 6-digit code');
      return;
    }
    setState(() => _error = null);
    ref.read(authNotifierProvider.notifier).verifyMfa(code);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final setupRequired = AuthTokenStore.instance.isMfaSetupRequired;
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((s) {
        s.whenOrNull(
          authenticated: () => context.go('/dashboard'),
          error: (msg) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg))),
        );
      });
    });

    final isLoading =
        authState.valueOrNull?.mapOrNull(loading: (_) => true) == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 56,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Two-Factor Authentication',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                setupRequired
                    ? 'Scan the QR code, then enter the 6-digit code'
                    : 'Enter the 6-digit code from your authenticator app',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (setupRequired) ...[
                const SizedBox(height: AppSpacing.lg),
                _MfaSetupPanel(
                  loading: _setupLoading,
                  error: _setupError,
                  qrBytes: _setupQrBytes,
                  secret: _setupSecret,
                  onRetry: () {
                    setState(() => _setupLoadStarted = false);
                    _loadMfaSetup();
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  hintText: '000000',
                  errorText: _error,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: const BorderSide(color: AppColors.onSurfaceVariant),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                enableInteractiveSelection: true,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 8,
                      fontSize: 32,
                    ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isLoading == true
                      ? null
                      : () {
                          if (_codeController.text.length == 6) {
                            _verify();
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading == true
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MfaSetupPanel extends StatelessWidget {
  const _MfaSetupPanel({
    required this.loading,
    required this.error,
    required this.qrBytes,
    required this.secret,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final Uint8List? qrBytes;
  final String? secret;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Column(
        children: [
          Text(
            error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry setup')),
        ],
      );
    }

    return Column(
      children: [
        if (qrBytes != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Image.memory(
                qrBytes!,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
        if (secret != null && secret!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.onSurfaceVariant),
            ),
            child: Column(
              children: [
                SelectableText(
                  secret!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onBackground,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: secret!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secret copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy manual key'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
