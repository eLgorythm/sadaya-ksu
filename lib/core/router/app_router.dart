import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/anggota/presentation/pages/members_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/simpanan/presentation/pages/savings_page.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  const AppRouter._();

  static GoRouter build(SupabaseClient client) => GoRouter(
        initialLocation: '/',
        refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
        redirect: (context, state) {
          final loggedIn = client.auth.currentSession != null;
          final isLoginRoute = state.matchedLocation == '/login';
          if (!loggedIn && !isLoginRoute) return '/login';
          if (loggedIn && isLoginRoute) return '/';
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginPage(),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => const HomePage(),
          ),
          GoRoute(
            path: '/anggota',
            builder: (_, _) => const MembersPage(),
          ),
          GoRoute(
            path: '/simpanan/:memberId',
            builder: (context, state) {
              final member = state.extra as MemberSavingsTarget?;
              if (member == null) {
                return const Scaffold(
                  body: Center(
                      child: Text('Buka halaman ini dari detail anggota.')),
                );
              }
              return SavingsPage(member: member);
            },
          ),
        ],
      );
}
