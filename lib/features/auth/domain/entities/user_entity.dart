import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.jabatan,
  });

  final String id;
  final String email;
  final String fullName;
  final String? jabatan;

  @override
  List<Object?> get props => [id, email, fullName, jabatan];
}
