import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/measurement_sheet.dart';
import '../widgets/programme_dialog.dart';

class ServiceRecordScreen extends ConsumerStatefulWidget {
  const ServiceRecordScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<ServiceRecordScreen> createState() => _ServiceRecordScreenState();
}

class _ServiceRecordScreenState extends ConsumerState<ServiceRecordScreen> {
  int _tab = 0;
  int? _programmeId;

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerDetailProvider(widget.customerId));
    final measurements = ref.watch(measurementsProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Service Record'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Before & After',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => context.push(Routes.customerBeforeAfter(widget.customerId)),
          ),
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.customerEdit(widget.customerId)),
          ),
        ],
      ),
      body: switch ((customer, measurements)) {
        (AsyncValue(:final error?), _) || (_, AsyncValue(:final error?)) => ErrorView(
            error: error,
            onRetry: () => refreshCustomer(ref, widget.customerId),
          ),
        (AsyncValue(value: final c?), AsyncValue(value: final m?)) => _content(c, m),
        _ => const SkeletonPage(headerHeight: 90, cards: 2, rows: 3),
      },
    );
  }

  Widget _content(Customer customer, List<Measurement> all) {
    final programmes = customer.programmes;
    final selected = programmes.where((p) => p.id == _programmeId).firstOrNull ?? programmes.firstOrNull;
    final rows = selected == null ? all : all.where((m) => m.programmeId == selected.id).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Hero(
                tag: 'customer-${customer.id}',
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: Text(
                    customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(customer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: context.palette.mint, borderRadius: BorderRadius.circular(20)),
                child: Text(customer.code, style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 14, 60, 8),
          child: PillTabs(labels: const ['Tracking', 'Progress'], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => refreshCustomer(ref, widget.customerId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              children: [
                _ProgrammeHeader(
                  customer: customer,
                  selected: selected,
                  onSelect: (id) => setState(() => _programmeId = id),
                ),
                const SizedBox(height: 12),
                if (_tab == 0) _MeasurementTable(rows: rows, customerId: customer.id, programmeId: selected?.id)
                else _ProgressView(rows: rows),
              ],
            ),
          ),
        ),
        if (_tab == 0)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton.icon(
                onPressed: () => showMeasurementSheet(context, customerId: customer.id, programmeId: selected?.id),
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text('Add Entry'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgrammeHeader extends StatelessWidget {
  const _ProgrammeHeader({required this.customer, required this.selected, required this.onSelect});

  final Customer customer;
  final Programme? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final programme = selected;
    if (programme == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No programme yet. Entries are shown without a programme.',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ),
              TextButton.icon(
                onPressed: () => showProgrammeDialog(context, customerId: customer.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Programme'),
              ),
            ],
          ),
        ),
      );
    }

    final palette = context.palette;
    final stat = TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary.withValues(alpha: 0.85), fontSize: 13);
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            child: Row(
              children: [
                if (customer.programmes.length > 1)
                  DropdownButton<int>(
                    value: programme.id,
                    underline: const SizedBox(),
                    style: TextStyle(fontWeight: FontWeight.w800, color: palette.textPrimary, fontSize: 15),
                    items: [
                      for (final p in customer.programmes) DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (id) => id == null ? null : onSelect(id),
                  )
                else
                  Text(programme.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Text('W: ${programme.totalWeeks}', style: stat),
                const SizedBox(width: 12),
                Text('WG: ${programme.weeksCompleted}', style: stat),
                const SizedBox(width: 12),
                Text('WN: ${programme.weeksRemaining}', style: stat),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) => v == 'new'
                      ? showProgrammeDialog(context, customerId: customer.id, nextNumber: customer.programmes.length + 1)
                      : showProgrammeDialog(context, customerId: customer.id, programme: programme),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit programme')),
                    PopupMenuItem(value: 'new', child: Text('New programme')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Goal: ', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: programme.goal ?? '-'),
                  ])),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: 18, color: palette.textSecondary),
                  onPressed: () => showProgrammeDialog(context, customerId: customer.id, programme: programme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementTable extends StatelessWidget {
  const _MeasurementTable({required this.rows, required this.customerId, required this.programmeId});

  final List<Measurement> rows;
  final int customerId;
  final int? programmeId;

  static const _headers = ['Date', 'Weight', 'Fat', 'BMI', 'Mus', 'V Fat', 'Body\nAge', 'Chest', 'Waist', 'HP', '24%', 'Total\nPoints'];
  static const _minRows = 8;

  List<String> _cells(Measurement m) => [
        Fmt.shortDate(m.recordedOn),
        Fmt.num1(m.weight),
        Fmt.num1(m.fatPercent),
        Fmt.num1(m.bmi),
        Fmt.num1(m.muscle),
        Fmt.num1(m.visceralFat),
        Fmt.numOrDash(m.bodyAge),
        Fmt.numOrDash(m.chest),
        Fmt.numOrDash(m.waist),
        m.hp ?? '-',
        m.rm24 ?? '-',
        Fmt.numOrDash(m.totalPoints),
      ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final border = BorderSide(color: palette.border);
    Widget cell(String text, {bool header = false, VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: Container(
            height: header ? 44 : 38,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: header ? 11.5 : 12.5,
                fontWeight: header ? FontWeight.w700 : FontWeight.w500,
                color: header ? palette.primary : palette.textPrimary,
              ),
            ),
          ),
        );

    final fillers = (_minRows - rows.length).clamp(0, _minRows);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          columnWidths: const {0: FixedColumnWidth(64)},
          border: TableBorder(horizontalInside: border, verticalInside: border),
          children: [
            TableRow(
              decoration: BoxDecoration(color: palette.mint),
              children: [for (final h in _headers) cell(h, header: true)],
            ),
            for (var r = 0; r < rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: r.isOdd ? palette.surfaceMuted : null),
                children: [
                  for (final text in _cells(rows[r]))
                    cell(
                      text,
                      onTap: () => showMeasurementSheet(context, customerId: customerId, programmeId: programmeId, measurement: rows[r]),
                    ),
                ],
              ),
            for (var i = 0; i < fillers; i++)
              TableRow(children: [for (final _ in _headers) cell('')]),
          ],
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.rows});

  final List<Measurement> rows;

  @override
  Widget build(BuildContext context) {
    final weights = rows.where((m) => m.weight != null).toList();
    final fats = rows.where((m) => m.fatPercent != null).toList();
    if (weights.length < 2 && fats.length < 2) {
      return const Card(
        child: EmptyView(
          icon: Icons.show_chart_rounded,
          title: 'Not enough data yet',
          message: 'Add at least two entries to see progress charts.',
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ChangeTile(label: 'Weight (kg)', values: weights.map((m) => m.weight!).toList(), color: AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: _ChangeTile(label: 'Fat %', values: fats.map((m) => m.fatPercent!).toList(), color: AppColors.warning)),
          ],
        ).staggered(0),
        const SizedBox(height: 12),
        if (weights.length >= 2)
          _LineCard(title: 'Weight Trend', rows: weights, value: (m) => m.weight!, color: AppColors.accent).staggered(1),
        const SizedBox(height: 12),
        if (fats.length >= 2)
          _LineCard(title: 'Fat % Trend', rows: fats, value: (m) => m.fatPercent!, color: AppColors.warning).staggered(2),
      ],
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.label, required this.values, required this.color});

  final String label;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final start = values.isEmpty ? null : values.first;
    final current = values.isEmpty ? null : values.last;
    final change = start == null || current == null ? null : current - start;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: context.palette.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(Fmt.num1(current), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            if (change != null)
              Text(
                '${change <= 0 ? '' : '+'}${change.toStringAsFixed(1)} since start',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: change <= 0 ? AppColors.accent : AppColors.danger,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.title, required this.rows, required this.value, required this.color});

  final String title;
  final List<Measurement> rows;
  final double Function(Measurement) value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final values = rows.map(value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.25).clamp(0.5, double.infinity);
    final decimals = (maxY - minY + 2 * pad) < 6 ? 1 : 0;
    final palette = context.palette;
    final axisStyle = TextStyle(fontSize: 10, color: palette.textSecondary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 12),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY - pad,
                  maxY: maxY + pad,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: palette.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(v.toStringAsFixed(decimals), style: axisStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= rows.length || v != i.toDouble()) return const SizedBox();
                          final step = (rows.length / 5).ceil();
                          if (i % step != 0 && i != rows.length - 1) return const SizedBox();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(Fmt.shortDate(rows[i].recordedOn), style: axisStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
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
