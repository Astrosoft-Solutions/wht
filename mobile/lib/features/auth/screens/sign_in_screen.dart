import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_login.text.trim(), _password.text);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(sessionNoticeProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(title: 'Sign In', subtitle: 'Welcome back! Track your wellness journey.'),
                if (notice != null)
                  _SessionNoticeCard(
                    notice: notice,
                    onDismiss: () => ref.read(sessionNoticeProvider.notifier).clear(),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                TextFormField(
                  controller: _login,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => requiredValidator(v, 'Email or mobile'),
                  decoration: const InputDecoration(hintText: 'Email or Mobile', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  validator: (v) => requiredValidator(v, 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 6),
                LoadingButton(onPressed: _submit, busy: _loading, label: 'Sign In'),
                const OrDivider(),
                GoogleButton(onPressed: _google, loading: _googleLoading),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: context.palette.textSecondary)),
                    TextButton(
                      onPressed: () => context.push(Routes.signUp),
                      child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionNoticeCard extends StatelessWidget {
  const _SessionNoticeCard({required this.notice, required this.onDismiss});

  final SessionNotice notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final deactivated = notice == SessionNotice.deactivated;
    final color = deactivated ? AppColors.danger : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: Gaps.l),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(deactivated ? Icons.block_rounded : Icons.lock_clock_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deactivated
                  ? 'Your account has been deactivated. Please contact support.'
                  : 'Your session has expired. Please sign in again.',
              style: TextStyle(color: context.palette.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDismiss),
        ],
      ),
    );
  }
}
