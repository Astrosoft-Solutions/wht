import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/widgets/auth_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _currentError;

  @override
  void dispose() {
    for (final c in [_current, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final message = await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text.isEmpty ? null : _current.text,
            newPassword: _new.text,
          );
      if (!mounted) return;
      showSnack(context, message);
      context.pop();
    } catch (e) {
      final error = ApiException.from(e);
      if (!mounted) return;
      if (error.fieldErrors.containsKey('current_password')) {
        setState(() => _currentError = error.fieldErrors['current_password']);
      } else {
        showSnack(context, error.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _strengthLabel(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return ['Weak', 'Fair', 'Good', 'Strong', 'Very strong'][score];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final strength = _new.text.isEmpty ? null : _strengthLabel(_new.text);
    final strengthIndex = strength == null ? 0 : ['Weak', 'Fair', 'Good', 'Strong', 'Very strong'].indexOf(strength);

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Gaps.l),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: p.mint, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: p.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Changing your password signs you out on your other devices. '
                      'If you signed up with Google, leave the current password empty.',
                      style: TextStyle(color: p.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gaps.l),
            PasswordField(controller: _current, label: 'Current password'),
            if (_currentError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(_currentError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _new,
              label: 'New password',
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              onChanged: (_) => setState(() {}),
            ),
            if (strength != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i < strengthIndex
                              ? [AppColors.danger, AppColors.warning, AppColors.accent, AppColors.brand][strengthIndex - 1]
                              : p.border,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Text(strength, style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirm,
              label: 'Confirm new password',
              validator: (v) => v != _new.text ? 'Passwords do not match' : null,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Gaps.xl),
            LoadingButton(onPressed: _save, busy: _saving, label: 'Update Password', icon: Icons.lock_reset_rounded),
          ],
        ),
      ),
    );
  }
}
