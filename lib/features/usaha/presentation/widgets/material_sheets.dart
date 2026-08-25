import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/usaha_entities.dart';
import '../cubit/usaha_form_cubits.dart';

/// Sheet tambah bahan baku baru.
class MaterialFormSheet extends StatefulWidget {
  const MaterialFormSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => const MaterialFormSheet(),
        ) ??
        false;
  }

  @override
  State<MaterialFormSheet> createState() => _MaterialFormSheetState();
}

class _MaterialFormSheetState extends State<MaterialFormSheet> {
  late final MaterialFormCubit _cubit = GetIt.I<MaterialFormCubit>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _unit = 'kg';

  static const _units = ['kg', 'gram', 'liter', 'biji', 'pack'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(name: _nameController.text, unit: _unit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MaterialFormCubit, UsahaFormState>(
        listener: (context, state) {
          switch (state) {
            case UsahaFormSuccess():
              SadayaMessage.success(context, 'Bahan baku tercatat');
              Navigator.of(context).pop(true);
            case UsahaFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is UsahaFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHeader(title: 'Bahan Baku Baru'),
                  Text('Hanya mendaftarkan jenis bahan. Pembelian stok '
                      'dicatat lewat tombol Beli di kartu bahan.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Bahan *',
                      prefixIcon: Icon(Icons.egg_alt_outlined),
                      hintText: 'mis. Kentang',
                    ),
                    validator: Validators.required('Nama bahan'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Satuan *',
                      prefixIcon: Icon(Icons.straighten_outlined),
                    ),
                    items: [
                      for (final u in _units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: saving ? null : (v) => setState(() => _unit = v!),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label:
                        Text(saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sheet catat pembelian/pemakaian bahan baku.
class MaterialTxSheet extends StatefulWidget {
  const MaterialTxSheet({
    super.key,
    required this.materials,
    required this.isPurchase,
    this.initialMaterialId,
  });

  static Future<bool> show(
    BuildContext context, {
    required List<RawMaterial> materials,
    required bool isPurchase,
    String? initialMaterialId,
  }) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => MaterialTxSheet(
            materials: materials,
            isPurchase: isPurchase,
            initialMaterialId: initialMaterialId,
          ),
        ) ??
        false;
  }

  final List<RawMaterial> materials;
  final bool isPurchase;
  final String? initialMaterialId;

  @override
  State<MaterialTxSheet> createState() => _MaterialTxSheetState();
}

class _MaterialTxSheetState extends State<MaterialTxSheet> {
  late final MaterialTxFormCubit _cubit = GetIt.I<MaterialTxFormCubit>();
  final _formKey = GlobalKey<FormState>();
  late String? _materialId = widget.initialMaterialId;
  String _unit = 'kg';
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();

  static const _units = ['kg', 'gram', 'liter', 'biji', 'pack'];

  @override
  void dispose() {
    for (final c in [_qtyController, _priceController, _notesController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: widget.isPurchase ? 'Tanggal Beli' : 'Tanggal Pakai',
    );
    if (picked != null) setState(() => _date = picked);
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _submit() {
    if (_materialId == null) {
      SadayaMessage.error(context, 'Pilih bahan baku dulu');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      materialId: _materialId!,
      isPurchase: widget.isPurchase,
      quantity: _parse(_qtyController.text),
      unitPrice: widget.isPurchase && _priceController.text.isNotEmpty
          ? _parse(_priceController.text.replaceAll('.', '').replaceAll(',', '.'))
          : null,
      date: _date,
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MaterialTxFormCubit, UsahaFormState>(
        listener: (context, state) {
          switch (state) {
            case UsahaFormSuccess():
              SadayaMessage.success(
                  context,
                  widget.isPurchase
                      ? 'Pembelian dicatat, stok bertambah'
                      : 'Pemakaian dicatat, stok berkurang');
              Navigator.of(context).pop(true);
            case UsahaFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is UsahaFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                      title: widget.isPurchase
                          ? 'Catat Pembelian Bahan'
                          : 'Catat Pemakaian Bahan'),
                  DropdownButtonFormField<String>(
                    initialValue: _materialId,
                    decoration: const InputDecoration(
                      labelText: 'Bahan Baku *',
                      prefixIcon: Icon(Icons.egg_alt_outlined),
                    ),
                    items: [
                      for (final m in widget.materials)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.name} (stok ${AppFormatters.number(m.currentStock)} ${m.unit})'),
                        ),
                    ],
                    onChanged:
                        saving ? null : (v) => setState(() => _materialId = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: widget.isPurchase
                            ? 'Tanggal Beli *'
                            : 'Tanggal Pakai *',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(AppFormatters.date(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah *',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: (value) {
                            final v = _parse(value ?? '');
                            if (v <= 0) return 'Jumlah harus lebih dari 0';
                            if (!widget.isPurchase && _materialId != null) {
                              final m = widget.materials
                                  .firstWhere((m) => m.id == _materialId);
                              if (v > m.currentStock) {
                                return 'Melebihi stok (${m.currentStock})';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                          ),
                          items: [
                            for (final u in _units)
                              DropdownMenuItem(value: u, child: Text(u)),
                          ],
                          onChanged: saving
                              ? null
                              : (v) => setState(() => _unit = v!),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isPurchase) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Harga per $_unit (Rp)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        hintText: 'opsional',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final v =
                            double.tryParse(value.replaceAll('.', '')) ?? -1;
                        if (v < 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(widget.isPurchase
                            ? Icons.shopping_cart_outlined
                            : Icons.outbound_outlined),
                    label: Text(saving
                        ? 'Menyimpan...'
                        : widget.isPurchase
                            ? 'Catat Pembelian'
                            : 'Catat Pemakaian'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
