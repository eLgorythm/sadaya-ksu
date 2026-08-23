import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.jabatan,
  });

  factory UserModel.fromSupabase(User user, Map<String, dynamic>? profile) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: (profile?['full_name'] as String?)?.isNotEmpty == true
          ? profile!['full_name'] as String
          : (user.email ?? ''),
      jabatan: profile?['jabatan'] as String?,
    );
  }
}
