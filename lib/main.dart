import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/secure_colors.dart';
import 'features/auth/data/matrix_auth_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_screen.dart';

void main() {
  // Ensure framework bindings are ready before execution
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate the core Matrix authentication engine
  final matrixAuthService = MatrixAuthService();

  runApp(
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(matrixAuthService),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix Secure Client',
      debugShowCheckedModeBanner: false, // Tactical layout - remove debug banner
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SecureColors.background,
        canvasColor: SecureColors.background,
        
        // Map color scheme to secure design specifications
        colorScheme: const ColorScheme.dark(
          background: SecureColors.background,
          surface: SecureColors.surfaceCharcoal,
          primary: SecureColors.textPrimary,
          secondary: SecureColors.cyberBlue,
          error: SecureColors.panicRed,
        ),
        
        // System-wide input and cursor configurations
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: SecureColors.cyberBlue,
          selectionColor: SecureColors.surfaceDarkSlate,
          selectionHandleColor: SecureColors.cyberBlue,
        ),
        
        // TabBar design synchronization
        tabBarTheme: const TabBarThemeData(
          indicatorColor: SecureColors.cyberBlue,
          labelColor: SecureColors.textPrimary,
          unselectedLabelColor: SecureColors.textSecondary,
        ),
        
        // Primary text configuration
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: SecureColors.textSecondary, fontFamily: 'Inter'),
        ),
      ),
      
      // Routing straight to AuthScreen target node
      home: const AuthScreen(),
    );
  }
}