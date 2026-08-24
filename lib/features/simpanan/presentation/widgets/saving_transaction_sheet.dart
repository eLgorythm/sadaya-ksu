import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/saving_entities.dart';
import '../cubit/saving_form_cubit.dart';

class SavingTransactionSheet extends StatefulWidget {
  const SavingTransactionSheet({
    super.key,
    required this.memberId,
    required this.transactionType,
    required this.types,
  });

  final String memberId;
  final String transactionType;
  final List<SavingsTypeEntity> types;

  static Future<bool> show(
    BuildContext context, {
    required String memberId,
    required String transactionType,
    required List<SavingsTypeEntity> types,
  }) async {
    final withdrawal = transactionType == 'withdrawal';
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => SavingTransactionSheet(
            memberId: memberId,
            transactionType: transactionType,
            types: withdrawal
                ? types.where((t) => t.isWithdrawable).toList()
                : types.where((t) => !t.isSystemManaged).toList(),
          ),
        ) ??
        false;
  }

  @override
  State<SavingTransactionSheet> createState() => _SavingTransactionSheetState();
}

class _SavingTransactionSheetState extends State<SavingTransactionSheet> {
  late final SavingFormCubit _cubit = GetIt.I<SavingFormCubit>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isDeposit => widget.transactionType == 'deposit';

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) _selectedType = widget.types.first;
  }

  SavingsTypeEntity? _selectedType;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;
    FocusScope.of(context).unfocus();
    final raw = _amountController.text.trim().replaceAll('.', '');
    _cubit.save(
      memberId: widget.memberId,
      type: _selectedType!,
      transactionType: widget.transactionType,
      amount: double.tryParse(raw) ?? 0,
      description: _noteController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<SavingFormCubit, SavingFormState>(
        listener: (context, state) {
          switch (state) {
            case SavingFormSuccess():
              SadayaMessage.success(
                context,
                _isDeposit
                    ? 'Setoran berhasil dicatat & diposting ke buku besar'
                    : 'Penarikan berhasil dicatat & diposting ke buku besar',
              );

              /// Tutup sheet sendiri dengan hasil true —
              /// halaman pemanggil yang me-reload saldo/riwayat.
              Navigator.of(context).pop(true);
            case SavingFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is SavingFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: _isDeposit
                        ? 'Setoran Simpanan'
                        : 'Penarikan Simpanan',
                  ),
                  const SizedBox(height: 12),
                  if (widget.types.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _isDeposit
                            ? 'Jenis simpanan belum tersedia.'
                            : 'Tidak ada simpanan yang dapat ditarik.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in widget.types)
                          ChoiceChip(
                            label: Text(type.code),
                            selected: _selectedType?.code == type.code,
                            onSelected: saving
                                ? null
                                : (_) => setState(() => _selectedType = type),
                            labelStyle: TextStyle(
                              fontWeight: _selectedType?.code == type.code
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    if (_selectedType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_selectedType!.name} • bunga ${(_selectedType!.interestRate * 100).toStringAsFixed(1)}%/tahun',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Nominal (Rp) *',
                        prefixIcon: Icon(Icons.payments_outlined),
                        hintText: 'mis. 20.000',
                      ),
                      validator: Validators.positiveAmount(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving || widget.types.isEmpty ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isDeposit
                                ? Icons.south_outlined
                                : Icons.north_outlined,
                          ),
                    label: Text(
                      saving
                          ? 'Memproses...'
                          : _isDeposit
                          ? 'Simpan Setoran'
                          : 'Simpan Penarikan',
                    ),
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
