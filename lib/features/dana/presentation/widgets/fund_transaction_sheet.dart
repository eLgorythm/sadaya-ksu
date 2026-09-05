import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/dana_entities.dart';
import '../cubit/fund_form_cubit.dart';

/// Sheet pencatatan kas masuk/keluar dana manual (sumber = 7 pos dana).
/// Menutup diri sendiri dengan hasil true; halaman pemanggil me-reload.
class FundTransactionSheet extends StatefulWidget {
  const FundTransactionSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => const FundTransactionSheet(),
        ) ??
        false;
  }

  @override
  State<FundTransactionSheet> createState() => _FundTransactionSheetState();
}

class _FundTransactionSheetState extends State<FundTransactionSheet> {
  late final FundFormCubit _cubit = GetIt.I<FundFormCubit>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _fundType = kFundPosOrder.first;
  bool _isIncoming = false;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
      fundType: _fundType,
      isIncoming: _isIncoming,
      amount: double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0,
      date: _date,
      description: _noteController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<FundFormCubit, FundFormState>(
        listener: (context, state) {
          switch (state) {
            case FundFormSuccess():
              SadayaMessage.success(context, 'Transaksi dana tercatat');
              Navigator.of(context).pop(true);
            case FundFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is FundFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHeader(title: 'Catat Kas Dana'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pos in kFundPosOrder)
                        ChoiceChip(
                          label: Text(kFundPosLabels[pos]!),
                          selected: _fundType == pos,
                          onSelected: saving
                              ? null
                              : (_) => setState(() => _fundType = pos),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Masuk'),
                        selected: _isIncoming,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _isIncoming = true),
                      ),
                      ChoiceChip(
                        label: const Text('Keluar'),
                        selected: !_isIncoming,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _isIncoming = false),
                      ),
                    ],
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
                      hintText: 'mis. 250.000',
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
