import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';
import '../providers/customer_providers.dart';

class BeforeAfterScreen extends ConsumerStatefulWidget {
  const BeforeAfterScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends ConsumerState<BeforeAfterScreen> {
  final _uploading = <String>{};

  Future<void> _pickPhoto(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;

    setState(() => _uploading.add(type));
    try {
      await ref.read(customerRepositoryProvider).uploadPhoto(widget.customerId, type, file);
      ref.invalidate(customerDetailProvider(widget.customerId));
      if (mounted) showSnack(context, '${type == 'before' ? 'Before' : 'After'} photo saved');
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _uploading.remove(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Before & After'), centerTitle: false),
      body: customer.when(
        loading: () => const Shimmering(
          child: Padding(
            padding: EdgeInsets.all(Gaps.l),
            child: Column(
              children: [
                Row(children: [Expanded(child: SkeletonBox(height: 220, radius: 16)), SizedBox(width: 12), Expanded(child: SkeletonBox(height: 220, radius: 16))]),
                SizedBox(height: Gaps.xl),
                SkeletonCard(height: 110),
                SkeletonCard(height: 110),
              ],
            ),
          ),
        ),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(customerDetailProvider(widget.customerId))),
        data: (c) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(c.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PhotoCard(
                    label: 'Before',
                    color: AppColors.danger,
                    photo: c.photo('before'),
                    uploading: _uploading.contains('before'),
                    onTap: () => _pickPhoto('before'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoCard(
                    label: 'After',
                    color: AppColors.accent,
                    photo: c.photo('after'),
                    uploading: _uploading.contains('after'),
                    onTap: () => _pickPhoto('after'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NoteField(
              key: ValueKey('health-${c.healthConditionBefore}'),
              title: 'Health Condition Before',
              initial: c.healthConditionBefore,
              onSave: (text) => _saveNotes(c, healthConditionBefore: text),
            ),
            const SizedBox(height: 16),
            _NoteField(
              key: ValueKey('remarks-${c.remarks}'),
              title: 'Remarks / Notes',
              initial: c.remarks,
              onSave: (text) => _saveNotes(c, remarks: text),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotes(Customer c, {String? healthConditionBefore, String? remarks}) async {
    try {
      await ref.read(customerRepositoryProvider).updateNotes(
            c.id,
            healthConditionBefore: healthConditionBefore ?? c.healthConditionBefore,
            remarks: remarks ?? c.remarks,
          );
      ref.invalidate(customerDetailProvider(c.id));
      if (mounted) showSnack(context, 'Notes saved');
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
      rethrow;
    }
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.label,
    required this.color,
    required this.photo,
    required this.uploading,
    required this.onTap,
  });

  final String label;
  final Color color;
  final CustomerPhoto? photo;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Material(
            color: p.mint,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: uploading ? null : onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo != null)
                    NetworkPhoto(url: photo!.url)
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: p.primary),
                        const SizedBox(height: 6),
                        Text('Add photo', style: TextStyle(color: p.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  if (photo != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.black45,
                        child: const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: uploading
                        ? Container(
                            key: const ValueKey('uploading'),
                            color: Colors.black38,
                            child: const Center(child: BrandLoader(size: 48)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({super.key, required this.title, required this.initial, required this.onSave});

  final String title;
  final String? initial;
  final Future<void> Function(String) onSave;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      // The error is already shown by the caller; keep the field in edit mode.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            if (_editing)
              TextButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save'))
            else
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 18, color: context.palette.textSecondary),
                onPressed: () => setState(() => _editing = true),
              ),
          ],
        ),
        TextField(
          controller: _controller,
          readOnly: !_editing,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: _editing ? 'Write here...' : 'Tap the pencil to add notes',
            fillColor: _editing ? context.palette.surface : context.palette.surfaceMuted,
          ),
        ),
      ],
    );
  }
}
