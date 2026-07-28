// test/widget_test.dart
//
// Smoke test: app starts, AuthScreen renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging/core/identity/identity_service.dart';
import 'package:messaging/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:messaging/features/auth/presentation/screens/auth_screen.dart';
import 'package:messaging/theme/secure_colors.dart';

void main() {
  testWidgets('AuthScreen renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: SecureColors.background,
        ),
        home: BlocProvider(
          create: (_) => AuthBloc(IdentityService()),
          child: const AuthScreen(),
        ),
      ),
    );

    await tester.pump();

    // Should show identity setup header
    expect(find.textContaining('IDENTITY'), findsWidgets);
  });
}
