import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/auth_token_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../presence/presentation/providers/presence_provider.dart';
import '../data/auth_repository_provider.dart';

/// Accepts a team invite: sets password from the link query `token`.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  static final RegExp _passwordStrength = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#^])',
  );

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 12) return 'Password must be at least 12 characters';
    if (!_passwordStrength.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return _validatePassword(value);
  }

  String _mapError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 429) {
        return 'Too many attempts. Wait a moment and try again.';
      }
      final data = e.response?.data;
      if (data is Map) {
        final apiMsg = data['error']?['message'];
        if (apiMsg is String && apiMsg.isNotEmpty) return apiMsg;
        if (apiMsg is List) return apiMsg.join(', ');
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invite link. Request a new invitation.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(authRepositoryProvider).acceptInvite(
            token: widget.token,
            password: _passwordController.text,
          );
      final mfaRequired = result['mfaRequired'] as bool? ?? false;
      final accessToken = result['accessToken'] as String?;

      if (mfaRequired) {
        AuthTokenStore.instance.setMfaPending(true);
        if (mounted) context.push('/mfa');
      } else {
        AuthTokenStore.instance.setMfaPending(false);
        if (accessToken != null && accessToken.isNotEmpty) {
          ref.read(presenceNotifierProvider.notifier).initialize(accessToken);
        }
        if (mounted) context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalidLink = widget.token.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'VAULTED',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w300,
                          fontSize: 28,
                          letterSpacing: 8,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Accept your invitation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (invalidLink)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'This invite link is missing a token. Open the link from your email, or ask an administrator to resend the invitation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: const BorderSide(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                      obscureText: true,
                      enabled: !_submitting,
                      enableInteractiveSelection: false,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: const BorderSide(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                      obscureText: true,
                      enabled: !_submitting,
                      enableInteractiveSelection: false,
                      validator: _validateConfirm,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: (_submitting || invalidLink) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
