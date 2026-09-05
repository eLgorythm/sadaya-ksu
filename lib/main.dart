import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    publishableKey: dotenv.get('SUPABASE_PUBLISHABLE_KEY'),
  );

  configureDependencies();

  runApp(SadayaApp(routerConfig: AppRouter.build(getIt<SupabaseClient>())));
}

class SadayaApp extends StatelessWidget {
  const SadayaApp({super.key, required this.routerConfig});

  final RouterConfig<Object> routerConfig;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: getIt<AuthCubit>(),
      child: MaterialApp.router(
        title: 'Sadaya',
        debugShowCheckedModeBanner: false,
        routerConfig: routerConfig,
        theme: AppTheme.light,
      ),
    );
  }
}
