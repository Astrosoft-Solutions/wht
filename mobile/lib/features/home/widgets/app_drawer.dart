import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/providers/auth_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    void navigate(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogoMark(size: 44, onDark: true),
                const SizedBox(height: 8),
                const AppWordmark(fontSize: 18, color: Colors.white),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                  Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                ],
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => navigate(() => context.go(Routes.home)),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Daily Habits'),
              onTap: () => navigate(() => context.go(Routes.habits)),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Customer Records'),
              onTap: () => navigate(() => context.push(Routes.customers)),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Reports'),
              onTap: () => navigate(() => context.go(Routes.reports)),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('My Plan'),
              onTap: () => navigate(() => context.push(Routes.myPlan)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => navigate(() => context.push(Routes.gallery)),
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Announcements'),
              onTap: () => navigate(() => context.push(Routes.announcements)),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => navigate(() => context.push(Routes.settings)),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
              onTap: () => navigate(() => ref.read(authControllerProvider.notifier).logout()),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
