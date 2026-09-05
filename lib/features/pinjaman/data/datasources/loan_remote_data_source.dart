import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class LoanRemoteDataSource {
  LoanRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchMemberLoans(String memberId) async {
    final rows = await _client
        .from('loans')
        .select()
        .eq('member_id', memberId)
        .order('disbursement_date', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchSchedules(String loanId) async {
    final rows = await _client
        .from('installment_schedules')
        /// Embed tanggal bayar (relasi FK schedule_id) agar UI bisa
        /// menampilkan "Dibayar pada <tanggal>" untuk jadwal lunas.
        .select('*, installment_payments(payment_date)')
        .eq('loan_id', loanId)
        .order('installment_number', ascending: true);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchLoanById(String loanId) async {
    final rows = await _client.from('loans').select().eq('id', loanId);
    if (rows.isEmpty) return null;
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rpcCreateLoan({
    required String memberId,
    required double principal,
    required int tenor,
    DateTime? disbursementDate,
    String? notes,
    String? loanType = 'regular',
  }) {
    return _client
        .rpc(
          'create_loan',
          params: {
            'p_member_id': memberId,
            'p_principal': principal,
            'p_tenor': tenor,
            'p_loan_type': loanType,

            /// PENTING: jangan kirim key dengan nilai null eksplisit —
            /// Postgres memperlakukannya sebagai NULL sungguhan sehingga
            /// DEFAULT current_date di RPC tidak berlaku.
            if (disbursementDate != null)
              'p_disbursement_date': disbursementDate
                  .toIso8601String()
                  .substring(0, 10),
            'p_notes': notes,
          },
        )
        .select()
        .single();
  }

  Future<void> rpcPayInstallment({
    required String scheduleId,
    double? principalPaid,
    double? interestPaid,
  }) async {
    await _client.rpc(
      'pay_installment',
      params: {
        'p_schedule_id': scheduleId,
        'p_principal_paid': principalPaid,
        'p_interest_paid': interestPaid,
      },
    );
  }
}
