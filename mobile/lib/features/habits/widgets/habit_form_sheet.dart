import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/habit_icon.dart';
import '../data/habit.dart';
import '../providers/habit_providers.dart';
import 'template_picker_sheet.dart';

Future<void> showHabitFormSheet(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => HabitFormSheet(habit: habit),
  );
}

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _icon;
  late TimeOfDay _start;
  TimeOfDay? _end;
  late Set<int> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _icon = h?.icon ?? 'water';
    _start = h != null ? _parse(h.startTime) : const TimeOfDay(hour: 6, minute: 0);
    _end = h?.endTime != null ? _parse(h!.endTime!) : null;
    _days = (h?.daysOfWeek == null || h!.daysOfWeek!.isEmpty) ? {1, 2, 3, 4, 5, 6, 7} : h.daysOfWeek!.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : (_end ?? _start.replacing(hour: (_start.hour + 1) % 24)),
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      showSnack(context, 'Pick at least one day', error: true);
      return;
    }
    if (_end != null && _hhmm(_end!).compareTo(_hhmm(_start)) <= 0) {
      showSnack(context, 'End time must be after start time', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final input = HabitInput(
        name: _name.text.trim(),
        icon: _icon,
        color: colorToHex(habitIconChoices[_icon]!.$2),
        startTime: _hhmm(_start),
        endTime: _end == null ? null : _hhmm(_end!),
        daysOfWeek: _days.length == 7 ? null : (_days.toList()..sort()),
      );
      await ref.read(habitActionsProvider).save(input, id: widget.habit?.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.habit == null ? 'New Habit' : 'Edit Habit',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.habit == null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    final parentContext = navigator.context;
                    navigator.pop();
                    showTemplatePickerSheet(parentContext);
                  },
                  icon: const Icon(Icons.library_add_check_outlined),
                  label: const Text('Add from templates'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or create your own', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                decoration: const InputDecoration(labelText: 'Habit name', hintText: 'e.g. Water Time - 1'),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in habitIconChoices.entries)
                    GestureDetector(
                      onTap: () => setState(() => _icon = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _icon == entry.key ? entry.value.$2.withValues(alpha: 0.15) : p.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _icon == entry.key ? entry.value.$2 : p.border, width: 1.5),
                        ),
                        child: AnimatedScale(
                          scale: _icon == entry.key ? 1.15 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(entry.value.$1, color: entry.value.$2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _timeField('Start', Fmt.time(_hhmm(_start)), () => _pickTime(start: true))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(
                      'End (optional)',
                      _end == null ? '--' : Fmt.time(_hhmm(_end!)),
                      () => _pickTime(start: false),
                      onClear: _end == null ? null : () => setState(() => _end = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= 7; i++)
                    GestureDetector(
                      onTap: () => setState(() => _days.contains(i) ? _days.remove(i) : _days.add(i)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _days.contains(i) ? AppColors.brandGradient : null,
                          color: _days.contains(i) ? null : p.mint,
                        ),
                        child: Text(
                          _weekdays[i - 1],
                          style: TextStyle(
                            color: _days.contains(i) ? Colors.white : p.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              LoadingButton(onPressed: _save, busy: _saving, label: 'Save Habit', icon: Icons.check_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, String value, VoidCallback onTap, {VoidCallback? onClear}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.schedule, size: 20),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
