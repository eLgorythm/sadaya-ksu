import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../cubit/loan_form_cubit.dart';

class CreateLoanSheet extends StatefulWidget {
  const CreateLoanSheet({super.key, required this.memberId});

  final String memberId;

  @override
  State<CreateLoanSheet> createState() => _CreateLoanSheetState();
}

class _CreateLoanSheetState extends State<CreateLoanSheet> {
  late final LoanFormCubit _cubit = GetIt.I<LoanFormCubit>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _tenor = 10;

  static const List<int> _tenorOptions = [3, 5, 10, 20, 30, 40, 50];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  double get _principal =>
      double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

  double get _rate => CreateLoanSheetLogic.rateForTenor(_tenor);

  double get _adminFee => (_principal * 0.03 * 100).roundToDouble() / 100;

  double get _monthlyPrincipal =>
      _principal > 0 ? _principal / _tenor : 0;

  double get _monthlyInterest => _principal * _rate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<LoanFormCubit, LoanFormState>(
        listener: (context, state) {
          if (state is LoanFormFailure) {
            SadayaMessage.error(context, state.message);
          }
        },
        builder: (context, state) {
          final saving = state is LoanFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHeader(title: 'Pinjaman Baru'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pinjaman (Rp) *',
                      prefixIcon: Icon(Icons.payments_outlined),
                      hintText: 'mis. 2.000.000',
                    ),
                    validator: Validators.positiveAmount(label: 'Jumlah pinjaman'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Text('Tenor (bulan)',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _tenorOptions)
                        ChoiceChip(
                          label: Text('$t'),
                          selected: _tenor == t,
                          onSelected: saving
                              ? null
                              : (_) => setState(() => _tenor = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InfoBox(
                    children: [
                      Text('Bunga ${(_rate * 100).toStringAsFixed(1)}%/bulan'
                          ' (${_tenor < 10 ? 'jangka pendek' : 'normal'})',
                          style: const TextStyle(fontSize: 12)),
                      if (_principal > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                            'Administrasi 3%: Rp ${_adminFee.toStringAsFixed(0)} (dipotong saat pencairan)',
                            style: const TextStyle(fontSize: 12)),
                        Text(
                            'Cicilan/bulan: pokok Rp ${_monthlyPrincipal.toStringAsFixed(0)} + jasa Rp ${_monthlyInterest.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan / agunan',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            FocusScope.of(context).unfocus();
                            _cubit.save(
                              memberId: widget.memberId,
                              principal: _principal,
                              tenor: _tenor,
                              notes: _notesController.text,
                            );
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_business_outlined),
                    label: Text(saving ? 'Memproses...' : 'Cairkan Pinjaman'),
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

/// Helper statis agar bisa dites tanpa widget.
class CreateLoanSheetLogic {
  CreateLoanSheetLogic._();

  static double rateForTenor(int tenor) => tenor < 10 ? 0.03 : 0.02;
}
