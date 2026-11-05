import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const supportEmail = 'support@wellnesshabittracker.com';

  static const _faqs = [
    (
      'Why can\'t I add customers?',
      'Adding customers needs an active Gold, Silver or Bronze plan, and each plan has a customer limit. Open My Plan to subscribe or upgrade.'
    ),
    (
      'How do habit reminders work?',
      'You get a reminder shortly before each habit starts, then repeating reminders until you mark it done. Manage them in Settings.'
    ),
    (
      'How do I renew my plan?',
      'Open My Plan and tap Renew. Renewing the same plan adds time after it ends; choosing another plan starts immediately.'
    ),
    (
      'I forgot my password.',
      'Tap "Forgot Password?" on the sign-in screen. We will email you a link to choose a new one.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('About & Help')),
      body: ListView(
        padding: const EdgeInsets.all(Gaps.l),
        children: [
          Center(
            child: Column(
              children: [
                const AppLogoMark(size: 60).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack, duration: 500.ms),
                const SizedBox(height: 10),
                const AppWordmark(fontSize: 22),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => Text(
                    snapshot.hasData ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})' : ' ',
                    style: TextStyle(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.xl),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const IconBadge(icon: Icons.mail_outline_rounded, color: AppColors.info, size: 36),
                  title: const Text('Email support', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(supportEmail),
                  onTap: () => launchUrl(Uri(scheme: 'mailto', path: supportEmail, query: 'subject=WellnessHabitTrack help')),
                ),
                const Divider(indent: 60),
                ListTile(
                  leading: const IconBadge(icon: Icons.language_rounded, color: AppColors.accent, size: 36),
                  title: const Text('Coach web panel', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage your plan and billing on the web'),
                  trailing: Icon(Icons.open_in_new_rounded, size: 18, color: p.textSecondary),
                  onTap: () => launchUrl(Uri.parse(Env.adminPanelUrl), mode: LaunchMode.externalApplication),
                ),
                const Divider(indent: 60),
                ListTile(
                  leading: IconBadge(icon: Icons.description_outlined, color: p.textSecondary, size: 36),
                  title: const Text('Open-source licences', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => showLicensePage(context: context, applicationName: 'WellnessHabitTrack'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.xl),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'FREQUENTLY ASKED',
              style: TextStyle(fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: p.textSecondary),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(_faqs[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [Text(_faqs[i].$2, style: TextStyle(color: p.textSecondary, height: 1.4))],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
