import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'theme/secure_colors.dart';
import 'config/routes/app_routes.dart';
import 'features/auth/data/matrix_auth_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final matrixAuthService = MatrixAuthService();
  await matrixAuthService.init();
  // Force application to clear session and launch directly into the identity login screen
  await matrixAuthService.logout();
  final initialRoute = AppRoutes.auth;

  runApp(
    MultiProvider(
      providers: [
        Provider<MatrixAuthService>.value(value: matrixAuthService),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(matrixAuthService),
        ),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix Secure Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SecureColors.background,
        canvasColor: SecureColors.background,
        colorScheme: const ColorScheme.dark(
          background: SecureColors.background,
          surface: SecureColors.surfaceCharcoal,
          primary: SecureColors.textPrimary,
          secondary: SecureColors.cyberBlue,
          error: SecureColors.panicRed,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: SecureColors.cyberBlue,
          selectionColor: SecureColors.surfaceDarkSlate,
          selectionHandleColor: SecureColors.cyberBlue,
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: SecureColors.cyberBlue,
          labelColor: SecureColors.textPrimary,
          unselectedLabelColor: SecureColors.textSecondary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: SecureColors.textSecondary, fontFamily: 'Inter'),
        ),
      ),
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
