import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../cubit/usaha_form_cubits.dart';

/// Tarik uang dari rekening bank (Buku Bank) ke kas Unit Krisado.
/// Menulis baris penarikan "debit" di Buku Bank + jurnal
/// Debit 1114 Kas Unit / Kredit 1112 Bank.
class ChipAmbilBankSheet extends StatefulWidget {
  const ChipAmbilBankSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => const ChipAmbilBankSheet(),
        ) ??
        false;
  }

  @override
  State<ChipAmbilBankSheet> createState() => _ChipAmbilBankSheetState();
}

class _ChipAmbilBankSheetState extends State<ChipAmbilBankSheet> {
  late final ChipAmbilBankFormCubit _cubit = GetIt.I<ChipAmbilBankFormCubit>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Transaksi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      amount: double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0,
      date: _date,
      description: _noteController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ChipAmbilBankFormCubit, UsahaFormState>(
        listener: (context, state) {
          switch (state) {
            case UsahaFormSuccess():
              SadayaMessage.success(context, 'Dana masuk kas unit');
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHeader(title: 'Ambil dari Bank'),
                  const SizedBox(height: 4),
                  Text(
                    'Tarik tunai dari rekening bank ke kas Unit Krisado.\n'
                    'Tercatat sebagai penarikan di Buku Bank (debit Bank / credit Kas Unit).',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp) *',
                      prefixIcon: Icon(Icons.payments_outlined),
                      hintText: 'mis. 5.000.000',
                    ),
                    validator: Validators.positiveAmount(label: 'Nominal'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Transaksi *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(AppFormatters.date(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan *',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: Validators.required('Keterangan'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
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
