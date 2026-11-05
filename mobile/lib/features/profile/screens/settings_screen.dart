import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../auth/providers/auth_controller.dart';
import '../../reminders/reminder_providers.dart';
import '../../reminders/reminder_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check after the user comes back from the system settings screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final allowed = await ReminderService.instance.notificationsAllowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(Gaps.l),
        children: [
          const _Label('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      IconBadge(icon: Icons.palette_outlined, color: AppColors.info, size: 36),
                      SizedBox(width: 12),
                      Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.brand,
                        selectedForegroundColor: Colors.white,
                      ),
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gaps.l),
          const _Label('Notifications'),
          Card(
            child: ReminderService.isSupported
                ? Column(
                    children: [
                      SwitchListTile(
                        secondary: const IconBadge(icon: Icons.notifications_active_outlined, color: AppColors.accent, size: 36),
                        title: const Text('Habit Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Before each habit starts, then repeating until it is done'),
                        value: ref.watch(remindersEnabledProvider),
                        onChanged: (value) async {
                          final enabled = await ref.read(remindersEnabledProvider.notifier).setEnabled(value);
                          await _checkPermission();
                          if (value && !enabled && context.mounted) {
                            showSnack(context, 'Allow notifications for this app in your phone settings to get reminders.', error: true);
                          }
                        },
                      ),
                      const Divider(indent: 60),
                      ListTile(
                        leading: IconBadge(
                          icon: _allowed == false ? Icons.notifications_off_outlined : Icons.verified_user_outlined,
                          color: _allowed == false ? AppColors.danger : AppColors.accent,
                          size: 36,
                        ),
                        title: const Text('System permission', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          switch (_allowed) {
                            true => 'Allowed',
                            false => 'Blocked. Reminders cannot appear.',
                            null => 'Checking...',
                          },
                          style: TextStyle(color: _allowed == false ? AppColors.danger : p.textSecondary),
                        ),
                        trailing: TextButton(
                          onPressed: () => ReminderService.instance.openSystemSettings(),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  )
                : ListTile(
                    leading: IconBadge(icon: Icons.notifications_off_outlined, color: p.textSecondary, size: 36),
                    title: const Text('Habit Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Reminders are available in the Android and iOS apps.'),
                  ),
          ),
          const SizedBox(height: Gaps.l),
          const _Label('Danger zone'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              leading: const IconBadge(icon: Icons.delete_forever_outlined, color: AppColors.danger, size: 36),
              title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
              subtitle: const Text('Permanently remove your account, habits and customers'),
              onTap: () => showDialog(context: context, builder: (_) => const _DeleteAccountDialog()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: context.palette.textSecondary),
      ),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _input = TextEditingController();

  /// Google-only accounts have no password and confirm by typing DELETE instead.
  bool _typedConfirm = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _ready => _typedConfirm ? _input.text.trim() == 'DELETE' : _input.text.isNotEmpty;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(password: _typedConfirm ? null : _input.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      final error = ApiException.from(e);
      if (!mounted) return;
      setState(() {
        if (error.fieldErrors.containsKey('confirm')) {
          _typedConfirm = true;
          _input.clear();
          _error = 'Your account has no password. Type DELETE to confirm.';
        } else {
          _error = error.fieldErrors['password'] ?? error.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This permanently deletes your profile, habits, customers, measurements and photos. '
            'Active plans are not refunded. This cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            obscureText: !_typedConfirm,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _typedConfirm ? 'Type DELETE' : 'Your password',
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _typedConfirm = !_typedConfirm;
              _input.clear();
              _error = null;
            }),
            child: Text(_typedConfirm ? 'Use my password instead' : 'Signed up with Google? Type DELETE instead'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(130, 44)),
          onPressed: _ready && !_busy ? _delete : null,
          child: _busy ? const DotsLoader(size: 6) : const Text('Delete forever'),
        ),
      ],
    );
  }
}
