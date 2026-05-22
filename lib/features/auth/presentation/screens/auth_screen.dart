import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../theme/secure_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/custom_server_text_field.dart';
import '../bloc/auth_bloc.dart';

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

  String _nodeStatus = "READY TO CONNECT";
  Color _statusColor = SecureColors.cryptoGreen;

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
      if (_loginUserArr.text.isEmpty || _loginPassArr.text.isEmpty) return;
      context.read<AuthBloc>().add(
        LoginRequested(
          node: serverNode,
          username: _loginUserArr.text,
          password: _loginPassArr.text,
        ),
      );
    } else {
      if (_regUserArr.text.isEmpty || _regPassArr.text.isEmpty) return;
      context.read<AuthBloc>().add(
        RegisterRequested(
          node: serverNode,
          username: _regUserArr.text,
          password: _regPassArr.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLoading) {
              setState(() {
                _nodeStatus = "ESTABLISHING LINK...";
                _statusColor = SecureColors.cyberBlue;
              });
            } else if (state is AuthSuccess) {
              setState(() {
                _nodeStatus = "SECURE LINK ACTIVE // ${state.userId}";
                _statusColor = SecureColors.cryptoGreen;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: SecureColors.surfaceDarkSlate,
                  content: Text(
                    "LINK ESTABLISHED SUCCESSFUL",
                    style: TextStyle(color: SecureColors.cryptoGreen, fontFamily: 'Inter'),
                  ),
                ),
              );
              // TODO: Ana ekrana yönlendirme kodunu buraya ekleyebilirsiniz.
            } else if (state is AuthFailure) {
              setState(() {
                _nodeStatus = "CONNECTION FAILED";
                _statusColor = Colors.redAccent;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1A0505),
                  content: Text(
                    state.message,
                    style: const TextStyle(color: Colors.redAccent, fontFamily: 'Inter', fontSize: 12.0),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Tactical Header & State Indicator
                  Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _nodeStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontFamily: 'Inter',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      onPressed: isLoading ? null : _executeAuthAction,
                      style: TextButton.styleFrom(
                        backgroundColor: SecureColors.textPrimary,
                        foregroundColor: SecureColors.background,
                        disabledBackgroundColor: SecureColors.surfaceDarkSlate,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      child: isLoading
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
            );
          },
        ),
      ),
    );
  }
}