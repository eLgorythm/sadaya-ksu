import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/usecases/bank_action.dart';
import '../cubit/bank_action_cubit.dart';

/// Sheet aksi Buku Bank (Muncul dari FAB saat tab Bank aktif).
/// Menerima satu aksi: dana masuk ke rekening atau cairkan ke kas.
class BankActionSheet extends StatefulWidget {
  const BankActionSheet({super.key, required this.action});

  final BankAction action;

  static Future<bool> show(
    BuildContext context, {
    required BankAction action,
  }) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => BankActionSheet(action: action),
        ) ??
        false;
  }

  @override
  State<BankActionSheet> createState() => _BankActionSheetState();
}

class _BankActionSheetState extends State<BankActionSheet> {
  late final BankActionCubit _cubit = GetIt.I<BankActionCubit>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();

  String get _title => switch (widget.action) {
        BankAction.danaMasuk => 'Dana Masuk ke Bank',
        BankAction.cairKas => 'Cairkan ke Kas',
      };

  String get _helper => switch (widget.action) {
        BankAction.danaMasuk => 'Catat pemasukan saldo bank dari luar '
            '(mis. investor) tanpa kategori.',
        BankAction.cairKas =>
          'Tarik tunai dari rekening bank ke kas (debit Kas / credit Bank).',
      };

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
    _cubit.save(BankActionParams(
      action: widget.action,
      amount: double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0,
      date: _date,
      description: _noteController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<BankActionCubit, BankActionState>(
        listener: (context, state) {
          switch (state) {
            case BankActionSuccess():
              SadayaMessage.success(
                context,
                widget.action == BankAction.danaMasuk
                    ? 'Saldo bank diperbarui'
                    : 'Dana dicairkan ke kas',
              );
              Navigator.of(context).pop(true);
            case BankActionFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is BankActionSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetHeader(title: _title),
                  const SizedBox(height: 4),
                  Text(
                    _helper,
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
                      hintText: 'mis. 10.000.000',
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
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
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