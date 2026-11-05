import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';
import '../providers/customer_providers.dart';

Future<void> showProgrammeDialog(BuildContext context, {required int customerId, Programme? programme, int nextNumber = 1}) {
  return showDialog(
    context: context,
    builder: (_) => _ProgrammeDialog(customerId: customerId, programme: programme, nextNumber: nextNumber),
  );
}

class _ProgrammeDialog extends ConsumerStatefulWidget {
  const _ProgrammeDialog({required this.customerId, this.programme, required this.nextNumber});

  final int customerId;
  final Programme? programme;
  final int nextNumber;

  @override
  ConsumerState<_ProgrammeDialog> createState() => _ProgrammeDialogState();
}

class _ProgrammeDialogState extends ConsumerState<_ProgrammeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.programme?.name ?? 'Programme ${widget.nextNumber}');
  late final _goal = TextEditingController(text: widget.programme?.goal ?? 'Weight Loss');
  late final _weeks = TextEditingController(text: '${widget.programme?.totalWeeks ?? 12}');
  late final _done = TextEditingController(text: '${widget.programme?.weeksCompleted ?? 0}');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _goal, _weeks, _done]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(customerRepositoryProvider).saveProgramme(
        widget.customerId,
        {
          'name': _name.text.trim(),
          'goal': _goal.text.trim().isEmpty ? null : _goal.text.trim(),
          'total_weeks': int.parse(_weeks.text),
          'weeks_completed': int.parse(_done.text),
        },
        id: widget.programme?.id,
      );
      refreshCustomer(ref, widget.customerId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(widget.programme == null ? 'New Programme' : 'Edit Programme'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _goal, decoration: const InputDecoration(labelText: 'Goal')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weeks,
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      decoration: const InputDecoration(labelText: 'Weeks (W)'),
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min 1' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _done,
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      decoration: const InputDecoration(labelText: 'Done (WG)'),
                      validator: (v) {
                        final done = int.tryParse(v ?? '');
                        if (done == null) return 'Required';
                        if (done > (int.tryParse(_weeks.text) ?? 0)) return 'Max W';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
