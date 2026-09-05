import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/loan_entities.dart';
import '../cubit/loan_payment_cubit.dart';

class PayInstallmentSheet extends StatelessWidget {
  PayInstallmentSheet({super.key, required this.schedule});

  final InstallmentScheduleEntity schedule;

  final LoanPaymentCubit _cubit = GetIt.I<LoanPaymentCubit>();

  @override
  Widget build(BuildContext context) {
    final breakdown = InterestDistributionBreakdown.fromInterest(
      schedule.interestAmount,
    );
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<LoanPaymentCubit, LoanPaymentState>(
        listener: (context, state) {
          switch (state) {
            case LoanPaymentSuccess():
              Navigator.of(context).pop(true);
            case LoanPaymentFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final processing = state is LoanPaymentInProgress;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: 'Bayar Cicilan ke-${schedule.installmentNumber}',
                ),
                const SizedBox(height: 8),
                InfoBox(
                  children: [
                    InfoRow(
                      label: 'Pokok',
                      value: AppFormatters.rupiah(schedule.principalAmount),
                    ),
                    InfoRow(
                      label: 'Bunga',
                      value: AppFormatters.rupiah(schedule.interestAmount),
                    ),
                    const Divider(height: 16),
                    InfoRow(
                      label: 'Total',
                      value: AppFormatters.rupiah(schedule.totalAmount),
                      bold: true,
                    ),
                    if (schedule.interestAmount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Distribusi bunga:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Japinup ${AppFormatters.rupiah(breakdown.japinup)} • '
                        'Kesra ${AppFormatters.rupiah(breakdown.kesra)} • '
                        'SWK ${AppFormatters.rupiah(breakdown.swk)}\n'
                        'Sosial ${AppFormatters.rupiah(breakdown.sosial)} • '
                        'Pendidikan ${AppFormatters.rupiah(breakdown.pendidikan)} • '
                        'CRK ${AppFormatters.rupiah(breakdown.crk)} • '
                        'Pembangunan ${AppFormatters.rupiah(breakdown.pembangunan)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: processing
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _cubit.pay(scheduleId: schedule.id);
                        },
                  icon: processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    processing
                        ? 'Memproses...'
                        : 'Bayar ${AppFormatters.rupiah(schedule.totalAmount)}',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
