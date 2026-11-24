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
  static const _maxRangeDays = 366;

  late DateTimeRange _range;
  final _captureKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _range = _thisMonthRange();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTimeRange _thisMonthRange() {
    final today = _today;
    return DateTimeRange(start: DateTime(today.year, today.month, 1), end: today);
  }

  DateTimeRange _clampRange(DateTime start, DateTime end) {
    final today = _today;
    var from = _dateOnly(start);
    var to = _dateOnly(end);
    if (to.isAfter(today)) to = today;
    if (from.isAfter(to)) from = to;
    final maxStart = to.subtract(const Duration(days: _maxRangeDays - 1));
    if (from.isBefore(maxStart)) from = maxStart;
    return DateTimeRange(start: from, end: to);
  }

  ReportRange get _queryRange => ReportRange(from: _range.start, to: _range.end);

  bool get _isThisMonth {
    final thisMonth = _thisMonthRange();
    return _range.start == thisMonth.start && _range.end == thisMonth.end;
  }

  int get _spanDays => _range.end.difference(_range.start).inDays + 1;

  String _rangeLabel() {
    if (_isThisMonth) return 'This Month (${Fmt.monthYear(_range.start)})';
    final last7 = _clampRange(_today.subtract(const Duration(days: 6)), _today);
    if (_range.start == last7.start && _range.end == last7.end) return 'Last 7 Days';
    final last30 = _clampRange(_today.subtract(const Duration(days: 29)), _today);
    if (_range.start == last30.start && _range.end == last30.end) return 'Last 30 Days';
    return Fmt.dateRange(_range.start, _range.end);
  }

  void _applyRange(DateTimeRange range) => setState(() => _range = _clampRange(range.start, range.end));

  void _shiftRange(int direction) {
    final days = _spanDays;
    final shiftedEnd = _range.end.add(Duration(days: days * direction));
    final shiftedStart = shiftedEnd.subtract(Duration(days: days - 1));
    final next = _clampRange(shiftedStart, shiftedEnd);
    if (next.start == _range.start && next.end == _range.end) return;
    setState(() => _range = next);
  }

  bool get _canGoForward => _range.end.isBefore(_today);

  Future<void> _pickRange() async {
    final today = _today;
    final choice = await showModalBottomSheet<_RangePreset>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final last7 = _clampRange(today.subtract(const Duration(days: 6)), today);
        final last30 = _clampRange(today.subtract(const Duration(days: 29)), today);
        final thisMonth = _thisMonthRange();

        Widget tile(String title, String subtitle, _RangePreset value, {bool selected = false}) {
          return ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: selected ? Icon(Icons.check_rounded, color: context.palette.primary) : null,
            onTap: () => Navigator.pop(context, value),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Date range', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              tile('This Month', Fmt.dateRange(thisMonth.start, thisMonth.end), _RangePreset.thisMonth, selected: _isThisMonth),
              tile(
                'Last 7 Days',
                Fmt.dateRange(last7.start, last7.end),
                _RangePreset.last7,
                selected: _range.start == last7.start && _range.end == last7.end,
              ),
              tile(
                'Last 30 Days',
                Fmt.dateRange(last30.start, last30.end),
                _RangePreset.last30,
                selected: _range.start == last30.start && _range.end == last30.end,
              ),
              ListTile(
                leading: Icon(Icons.date_range_rounded, color: context.palette.primary),
                title: const Text('Custom range'),
                subtitle: Text(Fmt.dateRange(_range.start, _range.end)),
                onTap: () => Navigator.pop(context, _RangePreset.custom),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case _RangePreset.thisMonth:
        _applyRange(_thisMonthRange());
      case _RangePreset.last7:
        _applyRange(DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today));
      case _RangePreset.last30:
        _applyRange(DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today));
      case _RangePreset.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: today,
          initialDateRange: _range,
          helpText: 'Select report dates',
          saveText: 'Apply',
        );
        if (picked != null && mounted) _applyRange(picked);
    }
  }

  String _summaryText(HabitReport r) {
    final best = r.trend.isEmpty ? null : r.trend.reduce((a, b) => b.percent > a.percent ? b : a);
    return [
      'WellnessHabitTrack - Habit Report (${Fmt.dateRange(_range.start, _range.end)})',
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

  Future<void> _share(BuildContext buttonContext, HabitReport r) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
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
      final subject = 'Habit Report - ${Fmt.dateRange(_range.start, _range.end)}';
      final text = _summaryText(r);
      if (asImage) {
        final fileName = 'habit-report-${Fmt.apiDate(_range.start)}_${Fmt.apiDate(_range.end)}.png';
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
    final range = _queryRange;
    final report = ref.watch(reportProvider(range));
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
            onRefresh: () => ref.refresh(reportProvider(range).future),
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
                              tooltip: 'Previous period',
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => _shiftRange(-1),
                            ),
                            Flexible(
                              child: ActionChip(
                                onPressed: _pickRange,
                                side: BorderSide(color: p.border),
                                backgroundColor: p.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                avatar: Icon(Icons.date_range_rounded, size: 18, color: p.primary),
                                label: Text(
                                  _rangeLabel(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next period',
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: _canGoForward ? () => _shiftRange(1) : null,
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
                          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(reportProvider(range))),
                          data: (r) => _ReportBody(key: ValueKey(range.key), report: r),
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

enum _RangePreset { thisMonth, last7, last30, custom }

class _ReportBody extends StatelessWidget {
  const _ReportBody({super.key, required this.report});

  final HabitReport report;

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
                            if (i < 0 || i >= trend.length) return const SizedBox();
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
