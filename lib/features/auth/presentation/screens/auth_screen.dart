import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/custom_server_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  
  // Controllers
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _loginUserArr = TextEditingController();
  final TextEditingController _loginPassArr = TextEditingController();
  final TextEditingController _regUserArr = TextEditingController();
  final TextEditingController _regPassArr = TextEditingController();

  // Simulated AuthBloc State Placeholder
  final bool _isLoading = false; 
  final String _nodeStatus = "READY TO CONNECT";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverController.dispose();
    _loginUserArr.dispose();
    _loginPassArr.dispose();
    _regUserArr.dispose();
    _regPassArr.dispose();
    super.dispose();
  }

  void _executeAuthAction() {
    final serverNode = _serverController.text.isEmpty ? "matrix.org" : _serverController.text;
    if (_tabController.index == 0) {
      // TODO: Emit AuthBloc Event -> LoginRequested(user: _loginUserArr.text, pass: _loginPassArr.text, node: serverNode)
    } else {
      // TODO: Emit AuthBloc Event -> RegisterRequested(user: _regUserArr.text, pass: _regPassArr.text, node: serverNode)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Tactical Header & State Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MATRIX // AUTH',
                    style: TextStyle(
                      color: SecureColors.textPrimary,
                      fontFamily: 'Inter',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SecureColors.cryptoGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _nodeStatus,
                        style: const TextStyle(
                          color: SecureColors.cryptoGreen,
                          fontFamily: 'Inter',
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Navigation Tabs Hierarchy
              TabBar(
                controller: _tabController,
                indicatorColor: SecureColors.cyberBlue,
                indicatorWeight: 2.0,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: SecureColors.textPrimary,
                unselectedLabelColor: SecureColors.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                tabs: const [
                  Tab(text: "IDENTITY_LOGIN"),
                  Tab(text: "GENERATE_KEY"),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Node Selection Shared Input Layer
              const Text(
                "TARGET NET-NODE",
                style: TextStyle(
                  color: SecureColors.textSecondary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              CustomServerTextField(controller: _serverController),
              
              const SizedBox(height: 16),
              
              // Dynamic Forms View Switcher
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Tab Layer
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "CREDENTIALS",
                            style: TextStyle(
                              color: SecureColors.textSecondary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AuthTextField(
                            controller: _loginUserArr,
                            hintText: "Matrix Username",
                          ),
                          AuthTextField(
                            controller: _loginPassArr,
                            hintText: "Passphrase",
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),
                    
                    // Registration Tab Layer
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "NEW SECURE IDENTITY",
                            style: TextStyle(
                              color: SecureColors.textSecondary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AuthTextField(
                            controller: _regUserArr,
                            hintText: "Desired Username",
                          ),
                          AuthTextField(
                            controller: _regPassArr,
                            hintText: "Master Passphrase",
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tactical Execution Button Layer
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: TextButton(
                  onPressed: _isLoading ? null : _executeAuthAction,
                  style: TextButton.styleFrom(
                    backgroundColor: SecureColors.textPrimary,
                    foregroundColor: SecureColors.background,
                    disabledBackgroundColor: SecureColors.surfaceDarkSlate,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(SecureColors.background),
                          ),
                        )
                      : const Text(
                          "ESTABLISH SECURE LINK",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}