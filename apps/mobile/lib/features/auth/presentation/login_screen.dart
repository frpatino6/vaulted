import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_state.dart';
import 'auth_notifier.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((state) {
        state.whenOrNull(
          mfaRequired: () => context.push('/mfa'),
          authenticated: () => context.go('/dashboard'),
        );
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: authState.when(
            data: (state) {
              final errorMsg = state.whenOrNull(error: (msg) => msg);
              // No mostrar errores de MFA en pantalla de login (vienen de volver atrás)
              final showError =
                  errorMsg != null &&
                  !errorMsg.toLowerCase().contains('verification code');
              return _LoginForm(
                state: state,
                error: showError ? errorMsg : null,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _LoginForm(
              state: const AuthState.initial(),
              error: e.toString(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.state, this.error});

  final AuthState state;
  final String? error;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill inmediatamente para que estén listos al primer tap
    _emailController.text = 'demo@vaulted.com';
    _passwordController.text = 'Test1234abcDEF';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.error!)));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && widget.error != oldWidget.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(widget.error!)));
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state.mapOrNull(loading: (_) => true) == true;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vaulted',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Everything you own. Protected. Organized. Yours.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) =>
                v == null || v.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
            ),
            obscureText: true,
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: isLoading == true
                    ? null
                    : () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter email and password'),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(authNotifierProvider.notifier)
                            .login(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );
                      },
                child: isLoading == true
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log in'),
              );
            },
          ),
        ],
      ),
    );
  }
}
