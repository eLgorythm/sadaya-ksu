import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/loan_entities.dart';
import '../../domain/repositories/loan_repository.dart' show LoanDetail;
import '../cubit/loan_form_cubit.dart';
import '../cubit/loan_payment_cubit.dart';
import '../cubit/loans_cubit.dart';
import '../widgets/create_loan_sheet.dart';
import '../widgets/pay_installment_sheet.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key, required this.member});

  final MemberLoanTarget member;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoansCubit>.value(
          value: GetIt.I<LoansCubit>()..load(member.id),
        ),
        BlocProvider<LoanFormCubit>.value(value: GetIt.I<LoanFormCubit>()),
      ],
      child: _LoansView(member: member),
    );
  }
}

class MemberLoanTarget {
  const MemberLoanTarget({
    required this.id,
    required this.name,
    required this.memberNumber,
  });

  final String id;
  final String name;
  final int memberNumber;
}

class _LoansView extends StatelessWidget {
  const _LoansView({required this.member});

  final MemberLoanTarget member;

  void _openCreateSheet(BuildContext context) {
    GetIt.I<LoanFormCubit>().reset();
    showSadayaBottomSheet(
      context: context,
      builder: (_) => CreateLoanSheet(memberId: member.id),
    );
  }

  void _confirmPayment(BuildContext context, InstallmentScheduleEntity s) {
    GetIt.I<LoanPaymentCubit>().reset();
    showSadayaBottomSheet<bool>(
      context: context,
      builder: (_) => PayInstallmentSheet(schedule: s),
    ).then((paid) {
      if (paid == true && context.mounted) {
        context.read<LoansCubit>().refreshDetail(memberId: member.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#${member.memberNumber} ${member.name}'),
      ),
      floatingActionButton: BlocBuilder<LoansCubit, LoansState>(
        builder: (context, state) {
          if (state is! LoansListLoaded) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openCreateSheet(context),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Pinjaman Baru'),
          );
        },
      ),
      body: BlocConsumer<LoanFormCubit, LoanFormState>(
        listener: (context, formState) {
          switch (formState) {
            case LoanFormSuccess(:final loan):
              Navigator.of(context).pop();
              SadayaMessage.success(
                context,
                'Pinjaman #${loan.loanNumber} dicairkan. Jadwal ${loan.tenor} cicilan dibuat.',
              );
              context.read<LoansCubit>().load(member.id);
            case LoanFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, _) => BlocBuilder<LoansCubit, LoansState>(
          builder: (context, state) {
            switch (state) {
              case LoansLoadInProgress():
                return const LoadingView();
              case LoansFailure(:final message):
                return ErrorStateView(
                  message: message,
                  onRetry: () => context.read<LoansCubit>().load(member.id),
                );
              case LoansListLoaded(:final loans):
                return _LoanListView(
                  memberId: member.id,
                  loans: loans,
                  onCreate: () => _openCreateSheet(context),
                );
              case LoansDetailLoaded(:final detail, :final justPaid):
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (justPaid) {
                    SadayaMessage.success(context,
                        'Pembayaran tercatat. Jasa terdistribusi otomatis ke 7 pos.');
                    context.read<LoansCubit>().refreshDetail(
                          memberId: member.id,
                        );
                  }
                });
                return _LoanDetailView(
                  key: ValueKey('${detail.loan.id}_${detail.loan.totalPaid}'),
                  detail: detail,
                  onBack: () =>
                      context.read<LoansCubit>().backToList(member.id),
                  onPay: (schedule) => _confirmPayment(context, schedule),
                );
              case LoansInitial():
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}

class _LoanListView extends StatelessWidget {
  const _LoanListView({
    required this.memberId,
    required this.loans,
    required this.onCreate,
  });

  final String memberId;
  final List<LoanEntity> loans;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            await context.read<LoansCubit>().load(memberId),
        child: const EmptyStateView(
          icon: Icons.account_balance_outlined,
          message: 'Belum ada pinjaman.\nTekan "Pinjaman Baru" untuk mengajukan.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => await context.read<LoansCubit>().load(memberId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: loans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final loan = loans[index];
          return _LoanCard(
            loan: loan,
            onTap: () => context.read<LoansCubit>().openDetail(
                  memberId: memberId,
                  loanId: loan.id,
                ),
          );
        },
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.onTap});

  final LoanEntity loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Pinjaman #${loan.loanNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  StatusBadge(
                    label: loan.isPaidOff ? 'LUNAS' : 'AKTIF',
                    status: loan.isPaidOff ? 'paid_off' : 'partial',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(AppFormatters.rupiah(loan.principalAmount),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${AppFormatters.date(loan.disbursementDate)} • '
                '${loan.tenor} bln • bunga ${(loan.interestRate * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: loan.progress,
                backgroundColor: Colors.grey.shade200,
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Sisa ${AppFormatters.rupiah(loan.remainingBalance)}',
                      style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text(
                      'Terbayar ${(loan.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanDetailView extends StatelessWidget {
  const _LoanDetailView({
    super.key,
    required this.detail,
    required this.onBack,
    required this.onPay,
  });

  final LoanDetail detail;
  final VoidCallback onBack;
  final ValueChanged<InstallmentScheduleEntity> onPay;

  @override
  Widget build(BuildContext context) {
    final loan = detail.loan;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Daftar Pinjaman'),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pinjaman #${loan.loanNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InfoRow(label: 'Pokok', value: AppFormatters.rupiah(loan.principalAmount)),
                InfoRow(label: 'Tenor', value: '${loan.tenor} bulan'),
                InfoRow(label: 'Bunga/bulan',
                    value: '${(loan.interestRate * 100).toStringAsFixed(2)}%'),
                InfoRow(label: 'Administrasi (3%)',
                    value: AppFormatters.rupiah(loan.adminFeeAmount)),
                InfoRow(label: 'Cicilan pokok/bln',
                    value: AppFormatters.rupiah(loan.monthlyPrincipal)),
                InfoRow(label: 'Jasa/bln',
                    value: AppFormatters.rupiah(loan.monthlyInterest)),
                const Divider(height: 20),
                InfoRow(label: 'Sisa pinjaman',
                    value: AppFormatters.rupiah(loan.remainingBalance),
                    bold: true),
                InfoRow(label: 'Sudah dibayar',
                    value:
                        '${AppFormatters.rupiah(loan.totalPaid)} (${(loan.progress * 100).toStringAsFixed(0)}%)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Jadwal Cicilan', style: Theme.of(context).textTheme.titleMedium),
        ...detail.schedules.map((s) => _ScheduleTile(
              schedule: s,
              canPay: loan.isActive && !s.isPaid,
              onPay: () => onPay(s),
            )),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.canPay,
    required this.onPay,
  });

  final InstallmentScheduleEntity schedule;
  final bool canPay;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final paid = schedule.isPaid;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: paid
              ? AppColors.primaryGreen.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.15),
          child: paid
              ? const Icon(Icons.check,
                  size: 16, color: AppColors.primaryGreen)
              : Text('${schedule.installmentNumber}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ),
        title: Text(
          'Cicilan ke-${schedule.installmentNumber} — ${AppFormatters.rupiah(schedule.totalAmount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: paid ? TextDecoration.lineThrough : null,
            color: paid ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          'Pokok ${AppFormatters.rupiah(schedule.principalAmount)} • '
          'Jasa ${AppFormatters.rupiah(schedule.interestAmount)}\n'
          'Jatuh tempo ${AppFormatters.date(schedule.dueDate)}'
          '${schedule.isPartial ? ' • sebagian terbayar' : ''}',
        ),
        isThreeLine: true,
        trailing: canPay
            ? FilledButton.tonal(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Bayar'))
            : null,
      ),
    );
  }
}

