import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

/// Service locator global aplikasi.
///
/// Registrasi dependency dilakukan oleh [configureDependencies] yang
/// implementasinya digenerate `injectable_generator` ke
/// `injection_container.config.dart` (hasil `dart run build_runner build`).
final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
