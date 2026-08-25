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

/// Sheet catat hasil produksi.
class ProductionSheet extends StatefulWidget {
  const ProductionSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => const ProductionSheet(),
        ) ??
        false;
  }

  @override
  State<ProductionSheet> createState() => _ProductionSheetState();
}

class _ProductionSheetState extends State<ProductionSheet> {
  late final ProductionFormCubit _cubit = GetIt.I<ProductionFormCubit>();
  final _formKey = GlobalKey<FormState>();
  String? _product;
  final _qtyController = TextEditingController();
  String _unit = 'kg';
  final _packController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();

  static const _units = ['kg', 'gram'];

  @override
  void dispose() {
    for (final c in [
      _qtyController,
      _packController,
      _costController,
      _notesController
    ]) {
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
      helpText: 'Tanggal Produksi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  double _parse(String text) =>
      double.tryParse(text.replaceAll(',', '.')) ?? -1;

  void _submit() {
    if (_product == null) {
      SadayaMessage.error(context, 'Pilih jenis produk dulu');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      productType: _product!,
      date: _date,
      quantity: _parse(_qtyController.text),
      unit: _unit,
      quantityPack: _packController.text.isEmpty
          ? null
          : _parse(_packController.text),
      cost: _costController.text.isEmpty
          ? null
          : double.tryParse(_costController.text.replaceAll('.', '')),
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ProductionFormCubit, UsahaFormState>(
        listener: (context, state) {
          switch (state) {
            case UsahaFormSuccess():
              SadayaMessage.success(context, 'Produksi tercatat');
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
                  const SheetHeader(title: 'Catat Produksi'),
                  DropdownButtonFormField<String>(
                    initialValue: _product,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Produk *',
                      prefixIcon: Icon(Icons.cookie_outlined),
                    ),
                    items: [
                      for (final e in kProductLabels.entries)
                        DropdownMenuItem(
                            value: e.key, child: Text(e.value)),
                    ],
                    onChanged:
                        saving ? null : (v) => setState(() => _product = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Produksi *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
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
                            labelText: 'Jumlah Hasil *',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: (value) {
                            final v = _parse(value ?? '');
                            if (v <= 0) return 'Jumlah harus lebih dari 0';
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _packController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Hasil Pack (opsional)',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      suffixText: 'pack',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final v = _parse(value);
                      if (v < 0) return 'Jumlah pack tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Biaya Produksi (Rp)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      hintText: 'opsional',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final v =
                          double.tryParse(value.replaceAll('.', '')) ?? -1;
                      if (v < 0) return 'Biaya tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
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
                        : const Icon(Icons.factory_outlined),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan'),
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

/// Sheet catat penjualan produk.
class SaleSheet extends StatefulWidget {
  const SaleSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => const SaleSheet(),
        ) ??
        false;
  }

  @override
  State<SaleSheet> createState() => _SaleSheetState();
}

class _SaleSheetState extends State<SaleSheet> {
  late final SaleFormCubit _cubit = GetIt.I<SaleFormCubit>();
  final _formKey = GlobalKey<FormState>();
  String? _product;
  String _unit = 'kg';
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _buyerController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();

  @override
  void dispose() {
    for (final c in [
      _qtyController,
      _priceController,
      _buyerController,
      _notesController,
    ]) {
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
      helpText: 'Tanggal Penjualan',
    );
    if (picked != null) setState(() => _date = picked);
  }

  double _parse(String text) =>
      double.tryParse(text.replaceAll(',', '.')) ?? -1;

  double get _total {
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.'));
    final price = double.tryParse(_priceController.text.replaceAll('.', ''));
    return qty != null && price != null && qty > 0 && price > 0
        ? qty * price
        : 0;
  }

  void _submit() {
    if (_product == null) {
      SadayaMessage.error(context, 'Pilih jenis produk dulu');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      productType: _product!,
      date: _date,
      quantity: _parse(_qtyController.text),
      unit: _unit,
      unitPrice: double.parse(_priceController.text.replaceAll('.', '')),
      buyer: _buyerController.text,
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<SaleFormCubit, UsahaFormState>(
        listener: (context, state) {
          switch (state) {
            case UsahaFormSuccess():
              SadayaMessage.success(context, 'Penjualan tercatat');
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
                  const SheetHeader(title: 'Catat Penjualan'),
                  DropdownButtonFormField<String>(
                    initialValue: _product,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Produk *',
                      prefixIcon: Icon(Icons.cookie_outlined),
                    ),
                    items: [
                      for (final e in kProductLabels.entries)
                        DropdownMenuItem(
                            value: e.key, child: Text(e.value)),
                    ],
                    onChanged:
                        saving ? null : (v) => setState(() => _product = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Penjualan *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
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
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Terjual *',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: (value) {
                            final v = _parse(value ?? '');
                            if (v <= 0) return 'Jumlah harus lebih dari 0';
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
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(
                                value: 'gram', child: Text('gram')),
                            DropdownMenuItem(
                                value: 'pack', child: Text('pack')),
                          ],
                          onChanged: saving
                              ? null
                              : (v) => setState(() => _unit = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Harga per $_unit (Rp) *',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    validator: Validators.positiveAmount(label: 'Harga'),
                  ),
                  if (_total > 0)
                    Card(
                      margin: const EdgeInsets.only(top: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Total Penjualan')),
                            Text(AppFormatters.rupiah(_total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Pembeli',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'mis. Warung Bu Sari / Toko X',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
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
                        : const Icon(Icons.sell_outlined),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan'),
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
