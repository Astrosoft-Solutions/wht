import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';
import '../providers/customer_providers.dart';

Future<void> showMeasurementSheet(
  BuildContext context, {
  required int customerId,
  int? programmeId,
  Measurement? measurement,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _MeasurementSheet(customerId: customerId, programmeId: programmeId, measurement: measurement),
  );
}

class _MeasurementSheet extends ConsumerStatefulWidget {
  const _MeasurementSheet({required this.customerId, this.programmeId, this.measurement});

  final int customerId;
  final int? programmeId;
  final Measurement? measurement;

  @override
  ConsumerState<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<_MeasurementSheet> {
  late DateTime _date;
  late final Map<String, TextEditingController> _fields;
  bool _saving = false;

  static const _labels = {
    'weight': 'Weight (kg)',
    'fat_percent': 'Fat %',
    'bmi': 'BMI (auto)',
    'muscle': 'Muscle (kg)',
    'visceral_fat': 'Visceral Fat',
    'body_age': 'Body Age',
    'chest': 'Chest (cm)',
    'waist': 'Waist (cm)',
    'hp': 'HP',
    'rm_24': '24%',
    'total_points': 'Total Points',
  };
  static const _integerFields = {'body_age', 'total_points'};
  static const _textFields = {'hp', 'rm_24'};

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _date = m?.recordedOn ?? DateTime.now();
    String n(num? v) => v == null ? '' : Fmt.numOrDash(v);
    final initial = {
      'weight': n(m?.weight),
      'fat_percent': n(m?.fatPercent),
      'bmi': n(m?.bmi),
      'muscle': n(m?.muscle),
      'visceral_fat': n(m?.visceralFat),
      'body_age': n(m?.bodyAge),
      'chest': n(m?.chest),
      'waist': n(m?.waist),
      'hp': m?.hp ?? '',
      'rm_24': m?.rm24 ?? '',
      'total_points': n(m?.totalPoints),
    };
    _fields = {for (final e in initial.entries) e.key: TextEditingController(text: e.value)};
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'recorded_on': Fmt.apiDate(_date),
      'programme_id': widget.programmeId ?? widget.measurement?.programmeId,
    };
    for (final entry in _fields.entries) {
      final text = entry.value.text.trim();
      if (_textFields.contains(entry.key)) {
        data[entry.key] = text.isEmpty ? null : text;
      } else if (_integerFields.contains(entry.key)) {
        data[entry.key] = int.tryParse(text);
      } else {
        data[entry.key] = double.tryParse(text);
      }
    }
    try {
      await ref.read(customerRepositoryProvider).saveMeasurement(widget.customerId, data, id: widget.measurement?.id);
      refreshCustomer(ref, widget.customerId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: 'Delete entry?', message: 'This measurement row will be removed.');
    if (!ok || !mounted) return;
    try {
      await ref.read(customerRepositoryProvider).deleteMeasurement(widget.customerId, widget.measurement!.id);
      refreshCustomer(ref, widget.customerId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _fields.keys.toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.measurement == null ? 'Add Entry' : 'Edit Entry',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                if (widget.measurement != null)
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: _delete),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(Fmt.chipDate(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < keys.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _input(keys[i])),
                    const SizedBox(width: 12),
                    Expanded(child: i + 1 < keys.length ? _input(keys[i + 1]) : const SizedBox()),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            LoadingButton(onPressed: _save, busy: _saving, label: 'Save Entry', icon: Icons.check_rounded),
          ],
        ),
      ),
    );
  }

  Widget _input(String key) {
    final isText = _textFields.contains(key);
    final isInt = _integerFields.contains(key);
    return TextField(
      controller: _fields[key],
      keyboardType: isText ? TextInputType.text : TextInputType.numberWithOptions(decimal: !isInt),
      inputFormatters: isText ? null : [FilteringTextInputFormatter.allow(RegExp(isInt ? r'[0-9]' : r'[0-9.]'))],
      decoration: InputDecoration(labelText: _labels[key], isDense: true),
    );
  }
}
