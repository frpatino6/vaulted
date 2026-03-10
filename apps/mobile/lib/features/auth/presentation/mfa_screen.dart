import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Two-factor authentication',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code from your authenticator app',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  hintText: '000000',
                  errorText: _error,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 8,
                    ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading == true
                    ? null
                    : () {
                        if (_codeController.text.length == 6) {
                          _verify();
                        }
                      },
                child: isLoading == true
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
