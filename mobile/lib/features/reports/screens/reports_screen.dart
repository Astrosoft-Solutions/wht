import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/report_repository.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _maxContentWidth = 600.0;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _captureKey = GlobalKey();
  bool _sharing = false;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = [for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i)];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Select month', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final m in months)
              ListTile(
                title: Text(Fmt.monthYear(m)),
                trailing: m == _month ? Icon(Icons.check_rounded, color: context.palette.primary) : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = next);
  }

  String _monthLabel() => _isCurrentMonth ? 'This Month (${Fmt.monthYear(_month)})' : Fmt.monthYear(_month);

  String _summaryText(MonthlyReport r) {
    final best = r.trend.isEmpty ? null : r.trend.reduce((a, b) => b.percent > a.percent ? b : a);
    return [
      'WellnessHabitTrack - Habit Report (${Fmt.monthYear(_month)})',
      '',
      'Completion: ${r.completionPercent}%',
      'Total Habits: ${r.totalHabits}',
      'Streak: ${r.streak} ${r.streak == 1 ? 'Day' : 'Days'}',
      'Completed: ${r.completed}',
      'Missed: ${r.missed}',
      if (best != null && best.total > 0) 'Best Day: ${Fmt.shortDate(best.date)} (${best.percent}%)',
    ].join('\n');
  }

  Future<XFile> _captureReportImage(String fileName) async {
    final boundary = _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png', name: fileName);
  }

  Future<void> _share(BuildContext buttonContext, MonthlyReport r) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    // iPad presents the share sheet as a popover anchored to this rectangle.
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    final asImage = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Share Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const IconBadge(icon: Icons.image_outlined, color: AppColors.accent, size: 38),
              title: const Text('Share as image'),
              subtitle: const Text('Stats and completion trend chart'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const IconBadge(icon: Icons.notes_rounded, color: AppColors.info, size: 38),
              title: const Text('Share as text'),
              subtitle: const Text('Short summary for chat or email'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (asImage == null || !mounted) return;

    setState(() => _sharing = true);
    try {
      final subject = 'Habit Report - ${Fmt.monthYear(_month)}';
      final text = _summaryText(r);
      if (asImage) {
        final fileName = 'habit-report-${Fmt.apiMonth(_month)}.png';
        final file = await _captureReportImage(fileName);
        await SharePlus.instance.share(ShareParams(
          files: [file],
          fileNameOverrides: [fileName],
          text: text,
          subject: subject,
          sharePositionOrigin: origin,
        ));
      } else {
        await SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not share the report', error: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = Fmt.apiMonth(_month);
    final report = ref.watch(monthlyReportProvider(key));
    final loaded = report.value;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: 'Share report',
              icon: _sharing
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: p.primary))
                  : const Icon(Icons.ios_share_rounded),
              onPressed: loaded == null || _sharing || report.isLoading ? null : () => _share(buttonContext, loaded),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(monthlyReportProvider(key).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    color: p.background,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => _shiftMonth(-1),
                            ),
                            ActionChip(
                              onPressed: _pickMonth,
                              side: BorderSide(color: p.border),
                              backgroundColor: p.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              avatar: Icon(Icons.calendar_month_rounded, size: 18, color: p.primary),
                              label: Text(_monthLabel(), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        report.when(
                          loading: () => const Shimmering(
                            child: Column(
                              children: [
                                Row(children: [Expanded(child: SkeletonBox(height: 92, radius: 16)), SizedBox(width: 12), Expanded(child: SkeletonBox(height: 92, radius: 16))]),
                                SizedBox(height: 12),
                                Row(children: [Expanded(child: SkeletonBox(height: 92, radius: 16)), SizedBox(width: 12), Expanded(child: SkeletonBox(height: 92, radius: 16))]),
                                SizedBox(height: 16),
                                SkeletonBox(height: 280, radius: 18),
                              ],
                            ),
                          ),
                          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(monthlyReportProvider(key))),
                          data: (r) => _ReportBody(key: ValueKey(key), report: r),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({super.key, required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final p = context.palette;
    Widget row(Widget a, Widget b) => SizedBox(
          height: 92,
          child: Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]),
        );

    return Column(
      children: [
        row(
          _StatTile(icon: Icons.check_circle_rounded, iconColor: AppColors.accent, background: p.tileGreen, label: 'Completion', value: r.completionPercent, suffix: '%'),
          _StatTile(icon: Icons.event_note_rounded, iconColor: AppColors.info, background: p.tileBlue, label: 'Total Habits', value: r.totalHabits),
        ).staggered(0),
        const SizedBox(height: 12),
        row(
          _StatTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.warning,
            background: p.tileOrange,
            label: 'Streak',
            value: r.streak,
            suffix: r.streak == 1 ? ' Day' : ' Days',
          ),
          _StatTile(icon: Icons.cancel_rounded, iconColor: AppColors.danger, background: p.tileRed, label: 'Missed', value: r.missed),
        ).staggered(1),
        const SizedBox(height: 16),
        _TrendCard(trend: r.trend).staggered(2),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.label,
    required this.value,
    this.suffix = '',
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final num value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: p.surface.withValues(alpha: 0.7), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedCount(
                    value: value,
                    suffix: suffix,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final barWidth = trend.length > 20 ? 6.0 : (trend.length > 10 ? 10.0 : 16.0);
    final labelStep = trend.length > 20 ? 5 : (trend.length > 10 ? 2 : 1);
    final axisStyle = TextStyle(fontSize: 10, color: p.textSecondary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 16),
              child: Text('Habit Completion Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (trend.isEmpty)
              const SizedBox(
                height: 200,
                child: EmptyView(icon: Icons.bar_chart_rounded, title: 'No data yet', message: 'Complete habits to see your trend.'),
              )
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  BarChartData(
                    minY: 0,
                    maxY: 100,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (_) => FlLine(color: p.border, strokeWidth: 1, dashArray: [4, 4]),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.brand,
                        getTooltipItem: (group, _, rod, _) {
                          final point = trend[group.x];
                          return BarTooltipItem(
                            '${Fmt.shortDate(point.date)}\n${point.completed}/${point.total} (${point.percent}%)',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (v, meta) => SideTitleWidget(meta: meta, child: Text('${v.toInt()}%', style: axisStyle)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i % labelStep != 0 && i != trend.length - 1) return const SizedBox();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(trend[i].date.day.toString().padLeft(2, '0'), style: axisStyle),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < trend.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: trend[i].percent.toDouble(),
                              width: barWidth,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: trend[i].percent >= 80
                                    ? const [AppColors.brand, AppColors.accent]
                                    : const [AppColors.accent, Color(0xFF81C784)],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: p.mint),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
