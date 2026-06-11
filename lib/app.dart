import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/academic_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/academic_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/shell_screen.dart';

class App extends StatelessWidget {
  final AuthRepository authRepo;
  final AcademicRepository academicRepo;
  const App({super.key, required this.authRepo, required this.academicRepo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepo)..restore()),
        ChangeNotifierProvider(create: (_) => AcademicProvider(academicRepo)),
      ],
      child: Builder(builder: (context) {
        final auth = context.watch<AuthProvider>();
        final router = GoRouter(
          refreshListenable: auth,
          redirect: (ctx, state) {
            if (auth.status == AuthStatus.unknown) return null;
            final loggingIn = state.matchedLocation == '/login';
            if (!auth.isLoggedIn) return loggingIn ? null : '/login';
            if (loggingIn) return '/';
            return null;
          },
          routes: [
            GoRoute(path: '/', builder: (_, __) => const ShellScreen()),
            GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          ],
        );
        return MaterialApp.router(
          title: 'Faltas iCEV',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: router,
        );
      }),
    );
  }
}
