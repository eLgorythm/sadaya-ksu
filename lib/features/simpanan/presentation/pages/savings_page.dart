import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive_scaffold.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/saving_entities.dart';
import '../cubit/savings_cubit.dart';
import '../widgets/saving_transaction_sheet.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key, required this.member});

  final MemberSavingsTarget member;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  late final SavingsCubit _cubit = GetIt.I<SavingsCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.load(widget.member.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavingsCubit>.value(
      value: _cubit,
      child: _SavingsView(member: widget.member),
    );
  }
}

/// Data anggota minimal yang dibutuhkan halaman simpanan.
class MemberSavingsTarget {
  const MemberSavingsTarget({
    required this.id,
    required this.name,
    required this.memberNumber,
  });

  final String id;
  final String name;
  final int memberNumber;
}

class _SavingsView extends StatelessWidget {
  const _SavingsView({required this.member});

  final MemberSavingsTarget member;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${member.memberNumber} ${member.name}')),
      body: MaxWidthBox(
        maxWidth: 720,
        child: BlocBuilder<SavingsCubit, SavingsState>(
          builder: (context, state) {
            switch (state) {
              case SavingsLoadInProgress():
                return const LoadingView();
              case SavingsFailure(:final message):
                return ErrorStateView(
                  message: message,
                  onRetry: () => GetIt.I<SavingsCubit>().load(member.id),
                );
              case SavingsLoadSuccess():
                return RefreshIndicator(
                  onRefresh: () async => await GetIt.I<SavingsCubit>().load(
                    member.id,
                    silent: true,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceCard(
                              label: 'Simpanan Pokok',
                              code: 'SP',
                              balance: state.summary.balanceOf('SP'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _BalanceCard(
                              label: 'Wajib Bulanan',
                              code: 'SWB',
                              balance: state.summary.balanceOf('SWB'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceCard(
                              label: 'Mana Suka',
                              code: 'SMS',
                              balance: state.summary.balanceOf('SMS'),
                              highlight: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _BalanceCard(
                              label: 'Wajib Kredit',
                              code: 'SWK',
                              balance: state.summary.balanceOf('SWK'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            SavingTransactionSheet.show(
                              context,
                              memberId: member.id,
                              transactionType: 'deposit',
                              types: state.types,
                            ).then((saved) {
                              if (saved)
                                GetIt.I<SavingsCubit>().load(
                                  member.id,
                                  silent: true,
                                );
                            }),
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text('Setor Simpanan'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: state.summary.balanceOf('SMS') > 0
                            ? () =>
                                  SavingTransactionSheet.show(
                                    context,
                                    memberId: member.id,
                                    transactionType: 'withdrawal',
                                    types: state.types,
                                  ).then((saved) {
                                    if (saved) {
                                      GetIt.I<SavingsCubit>().load(
                                        member.id,
                                        silent: true,
                                      );
                                    }
                                  })
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Tarik Simpanan (Mana Suka)'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Riwayat Transaksi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (state.summary.transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Belum ada transaksi simpanan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...state.summary.transactions.map(
                          (tx) => _TransactionTile(tx: tx),
                        ),
                    ],
                  ),
                );
              case SavingsInitial():
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.code,
    required this.balance,
    this.highlight = false,
  });

  final String label;
  final String code;
  final double balance;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryGreen.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.primaryGreen
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (highlight)
                const Icon(
                  Icons.account_balance_wallet,
                  size: 14,
                  color: AppColors.primaryGreen,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.rupiah(balance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: balance > 0
                  ? (highlight ? AppColors.primaryGreen : null)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final SavingTransactionEntity tx;

  @override
  Widget build(BuildContext context) {
    final deposit = tx.isDeposit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: deposit
            ? AppColors.primaryGreen.withValues(alpha: 0.15)
            : AppColors.negativeRed.withValues(alpha: 0.15),
        child: Icon(
          deposit ? Icons.south_west : Icons.north_east,
          size: 18,
          color: deposit ? AppColors.primaryGreen : AppColors.negativeRed,
        ),
      ),
      title: Text(
        '${deposit ? '+' : '-'} ${AppFormatters.rupiah(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: deposit ? AppColors.primaryGreen : AppColors.negativeRed,
        ),
      ),
      subtitle: Text(
        '${tx.typeCode} • ${AppFormatters.date(tx.date)}'
        '${tx.description == null || tx.description!.isEmpty ? '' : '\n${tx.description}'}',
      ),
      isThreeLine: (tx.description?.isNotEmpty ?? false),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tx.isVoid)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Chip(
                label: Text('Dibatalkan', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (tx.shuShareLabel != null) _ShareChip(label: tx.shuShareLabel!),
        ],
      ),
    );
  }
}

/// Chip tanda bagi hasil SHU "Dasim" / "Dapin" pada transaksi Dividen.
class _ShareChip extends StatelessWidget {
  const _ShareChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDasim = label == 'Dasim';
    final background = isDasim
        ? AppColors.brand50
        : AppColors.accentGold.withValues(alpha: 0.16);
    final foreground = isDasim ? AppColors.brand700 : const Color(0xFF8D6E00);
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.35)),
      padding: EdgeInsets.zero,
    );
  }
}
