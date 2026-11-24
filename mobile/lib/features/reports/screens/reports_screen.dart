import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/habit_icon.dart';
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
    final habitLines = r.habits
        .map((h) => '• ${h.name}: ${h.completionPercent}% (${h.completedCount}/${h.scheduledCount}, missed ${h.missedCount})')
        .join('\n');
    return [
      'WellnessHabitTrack - Habit Report (${Fmt.dateRange(_range.start, _range.end)})',
      '',
      'Completion: ${r.completionPercent}%',
      'Total Habits: ${r.totalHabits}',
      'Streak: ${r.streak} ${r.streak == 1 ? 'Day' : 'Days'}',
      'Completed: ${r.completed}',
      'Missed: ${r.missed}',
      if (best != null && best.total > 0) 'Best Day: ${Fmt.shortDate(best.date)} (${best.percent}%)',
      if (habitLines.isNotEmpty) ...['', 'Per habit:', habitLines],
    ].join('\n');
  }

  Future<XFile> _captureReportImage(String fileName) async {
    final boundary = _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png', name: fileName);
  }

  Future<void> _shareWhatsApp(String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) showSnack(context, 'Could not open WhatsApp', error: true);
  }

  Future<void> _share(BuildContext buttonContext, HabitReport r) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    final choice = await showModalBottomSheet<_ShareChoice>(
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
              leading: const IconBadge(icon: Icons.chat_rounded, color: Color(0xFF25D366), size: 38),
              title: const Text('Share on WhatsApp'),
              subtitle: const Text('Opens WhatsApp with the report summary'),
              onTap: () => Navigator.pop(context, _ShareChoice.whatsapp),
            ),
            ListTile(
              leading: const IconBadge(icon: Icons.image_outlined, color: AppColors.accent, size: 38),
              title: const Text('Share as image'),
              subtitle: const Text('Stats and completion trend chart'),
              onTap: () => Navigator.pop(context, _ShareChoice.image),
            ),
            ListTile(
              leading: const IconBadge(icon: Icons.notes_rounded, color: AppColors.info, size: 38),
              title: const Text('Share as text'),
              subtitle: const Text('Short summary for chat or email'),
              onTap: () => Navigator.pop(context, _ShareChoice.text),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _sharing = true);
    try {
      final subject = 'Habit Report - ${Fmt.dateRange(_range.start, _range.end)}';
      final text = _summaryText(r);
      switch (choice) {
        case _ShareChoice.whatsapp:
          await _shareWhatsApp(text);
        case _ShareChoice.image:
          final fileName = 'habit-report-${Fmt.apiDate(_range.start)}_${Fmt.apiDate(_range.end)}.png';
          final file = await _captureReportImage(fileName);
          await SharePlus.instance.share(ShareParams(
            files: [file],
            fileNameOverrides: [fileName],
            text: text,
            subject: subject,
            sharePositionOrigin: origin,
          ));
        case _ShareChoice.text:
          await SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not share the report', error: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _showFullDetails(HabitReport r, {_HabitDetailFilter initialFilter = _HabitDetailFilter.all}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) => _FullDetailsSheet(
        report: r,
        rangeLabel: Fmt.dateRange(_range.start, _range.end),
        initialFilter: initialFilter,
      ),
    );
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
                          data: (r) => _ReportBody(
                            key: ValueKey(range.key),
                            report: r,
                            onShowFullDetails: () => _showFullDetails(r),
                            onOpenCompletionDetails: () => _showFullDetails(r, initialFilter: _HabitDetailFilter.completed),
                            onOpenMissedDetails: () => _showFullDetails(r, initialFilter: _HabitDetailFilter.missed),
                            onShareWhatsApp: _sharing ? null : () => _shareWhatsApp(_summaryText(r)),
                          ),
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

enum _ShareChoice { whatsapp, image, text }

enum _HabitDetailFilter { all, missed, completed }

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    super.key,
    required this.report,
    required this.onShowFullDetails,
    required this.onOpenCompletionDetails,
    required this.onOpenMissedDetails,
    required this.onShareWhatsApp,
  });

  final HabitReport report;
  final VoidCallback onShowFullDetails;
  final VoidCallback onOpenCompletionDetails;
  final VoidCallback onOpenMissedDetails;
  final VoidCallback? onShareWhatsApp;

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
          _StatTile(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.accent,
            background: p.tileGreen,
            label: 'Completion',
            value: r.completionPercent,
            suffix: '%',
            onTap: onOpenCompletionDetails,
          ),
          _StatTile(
            icon: Icons.event_note_rounded,
            iconColor: AppColors.info,
            background: p.tileBlue,
            label: 'Total Habits',
            value: r.totalHabits,
            onTap: onShowFullDetails,
          ),
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
            onTap: onShowFullDetails,
          ),
          _StatTile(
            icon: Icons.cancel_rounded,
            iconColor: AppColors.danger,
            background: p.tileRed,
            label: 'Missed',
            value: r.missed,
            onTap: onOpenMissedDetails,
          ),
        ).staggered(1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShowFullDetails,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Show full details'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                onPressed: onShareWhatsApp,
                icon: const Icon(Icons.chat_rounded),
                label: const Text('WhatsApp'),
              ),
            ),
          ],
        ).staggered(2),
        const SizedBox(height: 16),
        _TrendCard(trend: r.trend).staggered(3),
      ],
    );
  }
}

class _FullDetailsSheet extends StatefulWidget {
  const _FullDetailsSheet({
    required this.report,
    required this.rangeLabel,
    this.initialFilter = _HabitDetailFilter.all,
  });

  final HabitReport report;
  final String rangeLabel;
  final _HabitDetailFilter initialFilter;

  @override
  State<_FullDetailsSheet> createState() => _FullDetailsSheetState();
}

class _FullDetailsSheetState extends State<_FullDetailsSheet> {
  late _HabitDetailFilter _filter = widget.initialFilter;

  List<HabitReportDetail> get _habits {
    final all = widget.report.habits;
    switch (_filter) {
      case _HabitDetailFilter.all:
        return List<HabitReportDetail>.of(all);
      case _HabitDetailFilter.missed:
        final list = all.where((h) => h.missedCount > 0).toList();
        list.sort((a, b) => b.missedCount.compareTo(a.missedCount));
        return list;
      case _HabitDetailFilter.completed:
        final list = all.where((h) => h.completedCount > 0).toList();
        list.sort((a, b) => b.completedCount.compareTo(a.completedCount));
        return list;
    }
  }

  String get _listTitle => switch (_filter) {
        _HabitDetailFilter.all => 'All habits',
        _HabitDetailFilter.missed => 'Missed habits',
        _HabitDetailFilter.completed => 'Completed habits',
      };

  (String, String) get _emptyCopy => switch (_filter) {
        _HabitDetailFilter.all => ('No habits yet', 'Add habits to see per-habit completion details.'),
        _HabitDetailFilter.missed => ('No missed habits', 'No missed habits in this range.'),
        _HabitDetailFilter.completed => ('No completed habits', 'No completed habits in this range.'),
      };

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final p = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final habits = _habits;
    final empty = _emptyCopy;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(widget.rangeLabel, style: TextStyle(color: p.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    label: 'Completion',
                    value: '${r.completionPercent}%',
                    color: AppColors.accent,
                    selected: false,
                    onTap: () => setState(() => _filter = _HabitDetailFilter.all),
                  ),
                  _DetailChip(
                    label: 'Total Habits',
                    value: '${r.totalHabits}',
                    color: AppColors.info,
                    selected: false,
                    onTap: () => setState(() => _filter = _HabitDetailFilter.all),
                  ),
                  _DetailChip(
                    label: 'Streak',
                    value: '${r.streak} ${r.streak == 1 ? 'Day' : 'Days'}',
                    color: AppColors.warning,
                    selected: false,
                    onTap: () => setState(() => _filter = _HabitDetailFilter.all),
                  ),
                  _DetailChip(
                    label: 'Missed',
                    value: '${r.missed}',
                    color: AppColors.danger,
                    selected: _filter == _HabitDetailFilter.missed,
                    onTap: () => setState(() => _filter = _HabitDetailFilter.missed),
                  ),
                  _DetailChip(
                    label: 'Completed',
                    value: '${r.completed}',
                    color: AppColors.brand,
                    selected: _filter == _HabitDetailFilter.completed,
                    onTap: () => setState(() => _filter = _HabitDetailFilter.completed),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_listTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: habits.isEmpty
                  ? EmptyView(icon: Icons.checklist_rounded, title: empty.$1, message: empty.$2)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _HabitDetailCard(habit: habits[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: selected ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: context.palette.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitDetailCard extends StatelessWidget {
  const _HabitDetailCard({required this.habit});

  final HabitReportDetail habit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitIcon(icon: habit.icon, color: habit.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text(
                  '${habit.completionPercent}%',
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: habit.scheduledCount == 0 ? 0 : habit.completionPercent / 100,
                minHeight: 7,
                backgroundColor: p.mint,
                color: parseHexColor(habit.color, fallback: p.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'Completion', value: '${habit.completionPercent}%')),
                Expanded(child: _MiniStat(label: 'Done', value: '${habit.completedCount}')),
                Expanded(child: _MiniStat(label: 'Scheduled', value: '${habit.scheduledCount}')),
                Expanded(child: _MiniStat(label: 'Missed', value: '${habit.missedCount}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, color: context.palette.textSecondary)),
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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final num value;
  final String suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
        ),
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
