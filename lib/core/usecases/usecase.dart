import '../utils/result.dart';

abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

class NoParams {
  const NoParams();
}
