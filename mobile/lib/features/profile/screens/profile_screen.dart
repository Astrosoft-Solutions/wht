import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/network_photo.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user.dart';
import '../../auth/providers/auth_controller.dart';
import '../../subscription/widgets/plan_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto(AppUser user) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (user.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remove photo', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final repo = ref.read(authRepositoryProvider);
    try {
      AppUser updated;
      if (choice == 'remove') {
        setState(() => _uploading = true);
        updated = await repo.deleteAvatar();
      } else {
        final file = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 800,
          imageQuality: 85,
        );
        if (file == null) return;
        setState(() => _uploading = true);
        updated = await repo.uploadAvatar(file);
      }
      ref.read(authControllerProvider.notifier).setUser(updated);
      if (mounted) showSnack(context, choice == 'remove' ? 'Photo removed' : 'Profile photo updated');
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final name = TextEditingController(text: user.name);
    final mobile = TextEditingController(text: user.mobile ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.phone_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      try {
        await ref.read(authControllerProvider.notifier).updateProfile(
              name: name.text.trim(),
              mobile: mobile.text.trim().isEmpty ? null : mobile.text.trim(),
            );
        if (mounted) showSnack(context, 'Profile updated');
      } catch (e) {
        if (mounted) showSnack(context, ApiException.from(e).message, error: true);
      }
    }
    name.dispose();
    mobile.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const Scaffold(body: LoadingView());
    final p = context.palette;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          GradientHeader(
            padding: EdgeInsets.fromLTRB(Gaps.l, MediaQuery.paddingOf(context).top + Gaps.l, Gaps.l, Gaps.xl),
            child: Column(
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: Gaps.l),
                _Avatar(user: user, uploading: _uploading, onTap: () => _changePhoto(user)),
                const SizedBox(height: Gaps.m),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                if (user.mobile != null) Text(user.mobile!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: Gaps.m),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (user.coachType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                        child: Text(capitalize(user.coachType), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    if (user.planTier != null) TierChip(tier: user.planTier!),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _editProfile(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.l, Gaps.l, Gaps.l, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  title: 'Account',
                  children: [
                    _MenuTile(
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.gold,
                      title: 'My Plan',
                      subtitle: user.planName ?? 'No active plan',
                      onTap: () => context.push(Routes.myPlan),
                    ),
                    _MenuTile(
                      icon: Icons.lock_reset_rounded,
                      color: AppColors.info,
                      title: 'Change Password',
                      onTap: () => context.push(Routes.changePassword),
                    ),
                  ],
                ).staggered(0),
                _Section(
                  title: 'Workspace',
                  children: [
                    _MenuTile(icon: Icons.groups_outlined, title: 'Customer Records', onTap: () => context.push(Routes.customers)),
                    _MenuTile(icon: Icons.checklist_rounded, title: 'Daily Habits', onTap: () => context.go(Routes.habits)),
                    _MenuTile(icon: Icons.bar_chart_rounded, title: 'Reports', onTap: () => context.go(Routes.reports)),
                    _MenuTile(icon: Icons.photo_library_outlined, title: 'Gallery', onTap: () => context.push(Routes.gallery)),
                    _MenuTile(icon: Icons.campaign_outlined, title: 'Announcements', onTap: () => context.push(Routes.announcements)),
                  ],
                ).staggered(1),
                _Section(
                  title: 'App',
                  children: [
                    _MenuTile(icon: Icons.settings_outlined, color: p.textSecondary, title: 'Settings', subtitle: 'Reminders, theme, notifications', onTap: () => context.push(Routes.settings)),
                    _MenuTile(icon: Icons.help_outline_rounded, color: p.textSecondary, title: 'About & Help', onTap: () => context.push(Routes.about)),
                  ],
                ).staggered(2),
                const SizedBox(height: Gaps.s),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                  onPressed: () async {
                    final ok = await confirmDialog(context, title: 'Logout?', message: 'You will need to sign in again.', confirm: 'Logout');
                    if (ok) await ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ).staggered(3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.uploading, required this.onTap});

  final AppUser user;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: ClipOval(
              child: Container(
                color: context.palette.mint,
                child: uploading
                    ? const Center(child: DotsLoader(color: AppColors.brand, size: 6))
                    : user.avatarUrl != null
                        ? NetworkPhoto(url: user.avatarUrl!)
                        : Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: context.palette.primary),
                            ),
                          ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: context.palette.textSecondary),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 60),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap, this.color, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      leading: IconBadge(icon: icon, color: color ?? p.primary, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
      trailing: Icon(Icons.chevron_right_rounded, color: p.textSecondary),
      onTap: onTap,
    );
  }
}
