import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../subscription/widgets/plan_widgets.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';
import '../providers/customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final int? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _fat = TextEditingController();
  final _bmi = TextEditingController();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _muscle = TextEditingController();
  final _bodyAge = TextEditingController();

  bool _active = true;
  bool _loading = true;
  bool _saving = false;
  bool _bmiEditedManually = false;
  Object? _loadError;

  bool get _isEdit => widget.customerId != null;

  List<TextEditingController> get _all =>
      [_code, _name, _phone, _height, _weight, _fat, _bmi, _chest, _waist, _muscle, _bodyAge];

  @override
  void initState() {
    super.initState();
    _load();
    _height.addListener(_autoBmi);
    _weight.addListener(_autoBmi);
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(customerRepositoryProvider);
      if (_isEdit) {
        _fill(await repo.get(widget.customerId!));
      } else {
        _code.text = await repo.nextCode();
      }
    } catch (e) {
      _loadError = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _fill(Customer c) {
    String n(num? v) => v == null ? '' : Fmt.numOrDash(v);
    final m = c.baseline;
    _code.text = c.code;
    _name.text = c.name;
    _phone.text = c.phone ?? '';
    _height.text = n(c.heightCm);
    _weight.text = n(m?.weight);
    _fat.text = n(m?.fatPercent);
    _bmi.text = n(m?.bmi);
    _chest.text = n(m?.chest);
    _waist.text = n(m?.waist);
    _muscle.text = n(m?.muscle);
    _bodyAge.text = n(m?.bodyAge);
    _active = c.isActive;
    _bmiEditedManually = m?.bmi != null && m?.bmi != calculateBmi(m?.weight, c.heightCm);
  }

  void _autoBmi() {
    if (_bmiEditedManually) return;
    final bmi = calculateBmi(double.tryParse(_weight.text), double.tryParse(_height.text));
    final text = bmi?.toString() ?? '';
    if (_bmi.text != text) _bmi.text = text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    double? d(TextEditingController c) => double.tryParse(c.text.trim());
    final data = {
      'customer_code': _code.text.trim(),
      'name': _name.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'height_cm': d(_height),
      'status': _active ? 'active' : 'inactive',
      'weight': d(_weight),
      'fat_percent': d(_fat),
      'bmi': d(_bmi),
      'chest': d(_chest),
      'waist': d(_waist),
      'muscle': d(_muscle),
      'body_age': int.tryParse(_bodyAge.text.trim()),
    };

    try {
      final saved = await ref.read(customerRepositoryProvider).save(data, id: widget.customerId);
      refreshCustomer(ref, saved.id);
      if (!mounted) return;
      showSnack(context, _isEdit ? 'Customer updated' : 'Customer added');
      context.pop();
    } catch (e) {
      final error = ApiException.from(e);
      if (!mounted) return;
      if (error.isPlanLimit) {
        await showUpgradeDialog(context, error.message);
      } else {
        showSnack(context, error.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Service Record'), centerTitle: false),
      body: _loading
          ? const SkeletonPage(headerHeight: 420, rows: 0)
          : _loadError != null
              ? ErrorView(error: _loadError!, onRetry: _load)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconBadge(icon: Icons.badge_outlined, color: context.palette.primary, size: 36),
                                  const SizedBox(width: 10),
                                  Text('Personal Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _field('Customer ID', _code, required: true, numeric: false),
                              _field('Name', _name, required: true, numeric: false, capitalize: true),
                              _field('Phone', _phone, numeric: false, keyboard: TextInputType.phone),
                              _pair(_field('Height (cm)', _height), _field('Weight (kg)', _weight)),
                              _pair(
                                _field('Fat %', _fat),
                                _field('BMI', _bmi, onChanged: (_) => _bmiEditedManually = _bmi.text.isNotEmpty),
                              ),
                              _pair(_field('Chest (cm)', _chest), _field('Waist (cm)', _waist)),
                              _pair(_field('Muscles (kg)', _muscle), _field('Body Age', _bodyAge, integer: true)),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w600)),
                                value: _active,
                                onChanged: (v) => setState(() => _active = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: LoadingButton(onPressed: _save, busy: _saving, label: 'Save', icon: Icons.check_rounded),
              ),
            ),
    );
  }

  Widget _pair(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool numeric = true,
    bool integer = false,
    bool capitalize = false,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger))],
            ),
            style: TextStyle(fontSize: 12.5, color: context.palette.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: capitalize ? TextCapitalization.words : TextCapitalization.none,
            keyboardType: keyboard ??
                (numeric ? TextInputType.numberWithOptions(decimal: !integer) : TextInputType.text),
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.allow(RegExp(integer ? r'[0-9]' : r'[0-9.]'))]
                : null,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (required && value.isEmpty) return '$label is required';
              if (numeric && value.isNotEmpty && double.tryParse(value) == null) return 'Invalid number';
              return null;
            },
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          ),
        ],
      ),
    );
  }
}
