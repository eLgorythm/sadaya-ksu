import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class MemberRemoteDataSource {
  MemberRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchMembers({
    required String search,
    required String? status,
  }) async {
    PostgrestFilterBuilder<List<dynamic>> query =
        _client.from('members').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    if (search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    final rows = await query.order('member_number', ascending: true);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<int> nextMemberNumber() async {
    final rows = await _client
        .from('members')
        .select('member_number')
        .order('member_number', ascending: false)
        .limit(1);
    if (rows.isEmpty) return 1;
    return ((rows.first['member_number'] as num).toInt()) + 1;
  }

  Future<Map<String, dynamic>> insertMember(Map<String, dynamic> values) {
    return _client.from('members').insert(values).select().single();
  }

  Future<Map<String, dynamic>> updateMember(
    String id,
    Map<String, dynamic> values,
  ) {
    return _client.from('members').update(values).eq('id', id).select().single();
  }

  Future<void> updateStatus(String id, String status) {
    return _client.from('members').update({'status': status}).eq('id', id);
  }
}
