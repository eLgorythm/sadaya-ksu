import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignOut {
  SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call(NoParams params) => _repository.signOut();
}
