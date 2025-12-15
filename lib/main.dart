import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    DevicePreview(
      enabled: !const bool.fromEnvironment('dart.vm.product'),
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (context) => DataProvider(Provider.of<AuthProvider>(context, listen: false)),
          // Não recria o DataProvider a cada notificação do AuthProvider — retorna o anterior se existir.
          update: (context, auth, previous) => previous ?? DataProvider(auth),
        ),
      ],
      child: Selector<AuthProvider, bool>(
        selector: (_, auth) => auth.isLoggedIn,
        builder: (context, isLoggedIn, _) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final appRouter = AppRouter(authProvider);

          return MaterialApp.router(
            title: 'Faltas Scraper',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            routerConfig: appRouter.router,
            debugShowCheckedModeBanner: false,
            locale: DevicePreview.locale(context),
            builder: (context, child) => child!,
          );
        },
      ),
    );
  }
}
