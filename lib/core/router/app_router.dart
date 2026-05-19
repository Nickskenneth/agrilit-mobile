import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/articles/presentation/screens/article_list_screen.dart';
import '../../features/articles/presentation/screens/article_detail_screen.dart';
import '../../features/sops/presentation/screens/sop_list_screen.dart';
import '../../features/sops/presentation/screens/sop_detail_screen.dart';
import '../../features/forum/presentation/screens/forum_list_screen.dart';
import '../../features/forum/presentation/screens/forum_detail_screen.dart';
import '../../features/forum/presentation/screens/forum_create_screen.dart';
import '../../features/disease_scan/presentation/screens/scan_screen.dart';
import '../../features/disease_scan/presentation/screens/scan_result_screen.dart';
import '../../features/disease_scan/presentation/screens/scan_history_screen.dart';
import '../widgets/main_shell.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/articles',
    redirect: (context, state) async {
      final auth = context.read<AuthProvider>();
      await auth.checkLoginStatus();
      final isLoggedIn = auth.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/articles';
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Main app dengan bottom navigation
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/articles',
            builder: (_, __) => const ArticleListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => ArticleDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sops',
            builder: (_, __) => const SopListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => SopDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/scan',
            builder: (_, __) => const ScanScreen(),
            routes: [
              GoRoute(
                path: 'result',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => ScanResultScreen(
                  scan: state.extra as dynamic,
                ),
              ),
              GoRoute(
                path: 'history',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const ScanHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/forum',
            builder: (_, __) => const ForumListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const ForumCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => ForumDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
