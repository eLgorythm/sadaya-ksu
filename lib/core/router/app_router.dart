import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/anggota/presentation/pages/member_picker_page.dart';
import '../../features/anggota/presentation/pages/members_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/aset/presentation/pages/aset_page.dart';
import '../../features/dana/presentation/pages/dana_page.dart';
import '../../features/usaha/presentation/pages/usaha_page.dart';
import '../../features/keuangan/presentation/pages/keuangan_page.dart';
import '../../features/pinjaman/presentation/pages/loans_page.dart';
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
            path: '/keuangan',
            builder: (_, _) => const KeuanganPage(),
          ),
          GoRoute(
            path: '/dana',
            builder: (_, _) => const DanaPage(),
          ),
          GoRoute(
            path: '/aset',
            builder: (_, _) => const AsetPage(),
          ),
          GoRoute(
            path: '/usaha',
            builder: (_, _) => const UsahaPage(),
          ),
          GoRoute(
            path: '/pilih-anggota',
            builder: (context, state) {
              final title = (state.extra as Map<String, dynamic>?)?['title']
                      as String? ??
                  'Pilih Anggota';
              return MemberPickerPage(title: title);
            },
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
          GoRoute(
            path: '/pinjaman/:memberId',
            builder: (context, state) {
              final member = state.extra as MemberLoanTarget?;
              if (member == null) {
                return const Scaffold(
                  body: Center(
                      child: Text('Buka halaman ini dari detail anggota.')),
                );
              }
              return LoansPage(member: member);
            },
          ),
        ],
      );
}
