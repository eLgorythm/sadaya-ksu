import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_data_source.dart';
import '../models/member_model.dart';

@LazySingleton(as: MemberRepository)
class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl(this._dataSource, this._supabase);

  final MemberRemoteDataSource _dataSource;
  final SupabaseClient _supabase;

  @override
  Future<Result<List<MemberEntity>>> getMembers(MemberFilters filters) async {
    try {
      final rows = await _dataSource.fetchMembers(
        search: filters.search.trim(),
        status: filters.status,
      );
      return Ok(rows.map(MemberModel.fromMap).toList());
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memuat data anggota (${e.message})'));
    } catch (_) {
      return const Err(
        Failure(message: 'Gagal memuat data anggota. Periksa koneksi internet'),
      );
    }
  }

  @override
  Future<Result<MemberEntity>> createMember({
    required String name,
    String? address,
    String? phone,
    required DateTime joinDate,
    String? notes,
  }) async {
    try {
      final number = await _dataSource.nextMemberNumber();
      final row = await _dataSource.insertMember({
        'member_number': number,
        'name': name,
        'address': address,
        'phone': phone,
        'join_date': joinDate.toIso8601String().substring(0, 10),
        'notes': notes,
        'status': 'active',
        'created_by': _supabase.auth.currentUser?.id,
      });
      return Ok(MemberModel.fromMap(row));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Err(Failure(message: 'Nomor anggota sudah dipakai'));
      }
      return Err(Failure(message: 'Gagal menyimpan anggota (${e.message})'));
    } catch (_) {
      return const Err(
        Failure(message: 'Gagal menyimpan anggota. Periksa koneksi internet'),
      );
    }
  }

  @override
  Future<Result<MemberEntity>> updateMember({
    required String id,
    required int memberNumber,
    required String name,
    String? address,
    String? phone,
    required DateTime joinDate,
    String? notes,
  }) async {
    try {
      final row = await _dataSource.updateMember(id, {
        'name': name,
        'address': address,
        'phone': phone,
        'join_date': joinDate.toIso8601String().substring(0, 10),
        'notes': notes,
      });
      return Ok(MemberModel.fromMap(row));
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal memperbarui anggota (${e.message})'));
    } catch (_) {
      return const Err(
        Failure(message: 'Gagal memperbarui anggota. Periksa koneksi internet'),
      );
    }
  }

  @override
  Future<Result<void>> setStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _dataSource.updateStatus(id, status);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(Failure(message: 'Gagal mengubah status (${e.message})'));
    } catch (_) {
      return const Err(
        Failure(message: 'Gagal mengubah status. Periksa koneksi internet'),
      );
    }
  }
}
