import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

const tierColors = <String, (Color, Color)>{
  'gold': (Color(0xFFB8860B), Color(0xFFFFF4CC)),
  'silver': (Color(0xFF5F6B7A), Color(0xFFECEFF3)),
  'bronze': (Color(0xFF8C5A2B), Color(0xFFF6E6D8)),
};

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);

String formatRupees(double amount) => _inr.format(amount);

String capitalize(String? value) => value == null || value.isEmpty ? '-' : value[0].toUpperCase() + value.substring(1);

class TierChip extends StatelessWidget {
  const TierChip({super.key, required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tierColors[tier] ?? (context.palette.primary, context.palette.mint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: context.isDark ? fg.withValues(alpha: 0.2) : bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: context.isDark ? Color.lerp(fg, Colors.white, 0.45) : fg),
          const SizedBox(width: 4),
          Text(
            capitalize(tier),
            style: TextStyle(color: context.isDark ? Color.lerp(fg, Colors.white, 0.45) : fg, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Shown when the API refuses an action because of the coach's plan.
Future<void> showUpgradeDialog(BuildContext context, String message) async {
  final upgrade = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 36),
      title: const Text('Upgrade your plan'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('View Plans'),
        ),
      ],
    ),
  );
  if (upgrade == true && context.mounted) context.push(Routes.plans);
}
