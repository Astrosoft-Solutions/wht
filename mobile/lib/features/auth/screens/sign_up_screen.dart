import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

const _coachTypes = [
  ('consultant', 'Consultant', Icons.business_center_rounded, 'Advise clients on wellness plans'),
  ('coach', 'Coach', Icons.sports_rounded, 'Train and track your customers'),
  ('guide', 'Guide', Icons.explore_rounded, 'Mentor and support daily habits'),
];

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _coachType = 'coach';
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _mobile, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            mobile: _mobile.text.trim(),
            password: _password.text,
            coachType: _coachType,
          );
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(title: 'Create Account', subtitle: 'Start building healthy habits today.'),
                Text('I am a', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (value, label, icon, hint) in _coachTypes)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: value == 'guide' ? 0 : 8),
                          child: _CoachTypeCard(
                            label: label,
                            icon: icon,
                            hint: hint,
                            selected: _coachType == value,
                            onTap: () => setState(() => _coachType = value),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => requiredValidator(v, 'Name'),
                  decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Mobile (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                LoadingButton(onPressed: _submit, busy: _loading, label: 'Create Account'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: TextStyle(color: context.palette.textSecondary)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _CoachTypeCard extends StatelessWidget {
  const _CoachTypeCard({required this.label, required this.icon, required this.hint, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: hint,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 220),
                child: Icon(icon, color: selected ? Colors.white : p.primary, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? Colors.white : p.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
