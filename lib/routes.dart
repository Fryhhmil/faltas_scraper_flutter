import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSettings = state.matchedLocation == '/settings';

      // Permite acesso à tela de configurações mesmo quando não está logado
      if (isSettings) {
        return null;
      }

      // Se não estiver logado e não estiver na tela de login, redireciona para login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Se estiver logado e estiver na tela de login, redireciona para home
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      // Sem redirecionamento
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
}
