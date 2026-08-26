import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tax_entities.dart';
import '../../domain/usecases/tax_usecases.dart';
import '../cubits/pajak_cubit.dart';

class PajakFormSheet extends StatefulWidget {
  const PajakFormSheet({super.key, this.tax});

  final TaxItem? tax;

  static Future<bool> show(BuildContext context, {TaxItem? tax}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PajakFormSheet(tax: tax),
    );
    return result ?? false;
  }

  @override
  State<PajakFormSheet> createState() => _PajakFormSheetState();
}

class _PajakFormSheetState extends State<PajakFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _refCtrl;
  late final TextEditingController _notesCtrl;
  DateTime _selectedDate = DateTime.now();
  String _taxType = 'PPh 21';
  String _status = 'unpaid';

  bool get _isEditing => widget.tax != null;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.tax?.description ?? '');
    _amountCtrl = TextEditingController(
      text: widget.tax != null ? widget.tax!.amount.toStringAsFixed(0) : '',
    );
    _refCtrl = TextEditingController(text: widget.tax?.referenceNumber ?? '');
    _notesCtrl = TextEditingController(text: widget.tax?.notes ?? '');
    if (widget.tax != null) {
      _selectedDate = widget.tax!.taxDate;
      _taxType = widget.tax!.taxType;
      _status = widget.tax!.status;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final params = InsertTaxParams(
      taxType: _taxType,
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
      date: _selectedDate,
      status: _status,
      referenceNumber: _refCtrl.text.isEmpty ? null : _refCtrl.text,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    final cubit = GetIt.I<PajakCubit>();
    if (_isEditing) {
      await cubit.update(params, widget.tax!.id);
    } else {
      await cubit.insert(params);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Pajak' : 'Tambah Pajak',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Tax type
              DropdownButtonFormField<String>(
                initialValue: _taxType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Pajak',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PPh 21', child: Text('PPh 21')),
                  DropdownMenuItem(value: 'PPh 23', child: Text('PPh 23')),
                  DropdownMenuItem(value: 'PPN', child: Text('PPN')),
                  DropdownMenuItem(value: 'Pajak Lainnya', child: Text('Pajak Lainnya')),
                ],
                onChanged: (v) => setState(() => _taxType = v!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final n = double.tryParse(v.replaceAll('.', ''));
                  if (n == null || n <= 0) return 'Harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'unpaid', child: Text('Belum Dibayar')),
                  DropdownMenuItem(value: 'paid', child: Text('Sudah Dibayar')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),

              // Reference number
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor Referensi (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Pajak'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
