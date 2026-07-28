// lib/features/auth/presentation/screens/auth_screen.dart
//
// LAYER: features/auth/presentation
// RESPONSIBILITY: UI for local identity creation and import.
//
// No Matrix homeserver fields. No passwords. No network calls from this screen.
// The user either generates a new keypair or pastes an exported identity blob.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../theme/secure_colors.dart';
import '../../../chat/bloc/chat_list_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../bloc/auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _blobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _generate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AuthBloc>().add(GenerateIdentityRequested(displayName: name));
  }

  void _import() {
    final blob = _blobController.text.trim();
    if (blob.isEmpty) return;
    context.read<AuthBloc>().add(ImportIdentityRequested(blob: blob));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthReady) {
              try {
                context.read<ChatListCubit>();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.chatList,
                  (_) => false,
                );
              } catch (_) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.settings,
                  (_) => false,
                );
              }
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1A0505),
                  content: Text(
                    state.message,
                    style: const TextStyle(
                      color: SecureColors.panicRed,
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                    ),
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
                  const SizedBox(height: 48),

                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SECURELINK // IDENTITY SETUP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SecureColors.textPrimary,
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SecureColors.cryptoGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LOCAL ONLY',
                        style: TextStyle(
                          color: SecureColors.cryptoGreen,
                          fontFamily: 'Inter',
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'No server required. Your keys never leave this device.',
                    style: TextStyle(
                      color: SecureColors.textSecondary,
                      fontFamily: 'Inter',
                      fontSize: 11.0,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: SecureColors.cyberBlue,
                    indicatorWeight: 2.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: SecureColors.textPrimary,
                    unselectedLabelColor: SecureColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    tabs: const [
                      Tab(text: 'GENERATE'),
                      Tab(text: 'IMPORT'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── Generate Tab ───────────────────────────────────
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'DISPLAY NAME',
                                style: TextStyle(
                                  color: SecureColors.textSecondary,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AuthTextField(
                                controller: _nameController,
                                hintText: 'alice',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'A local-only label. Shared only when you share your contact address.',
                                style: TextStyle(
                                  color: SecureColors.textSecondary,
                                  fontSize: 11.0,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _InfoRow(
                                icon: Icons.lock_outline,
                                text: 'Ed25519 keypair generated on this device',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.cloud_off_outlined,
                                text: 'No registration on any server',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.key_outlined,
                                text: 'Private key never transmitted',
                              ),
                            ],
                          ),
                        ),

                        // ── Import Tab ─────────────────────────────────────
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'IDENTITY BLOB',
                                style: TextStyle(
                                  color: SecureColors.textSecondary,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AuthTextField(
                                controller: _blobController,
                                hintText: 'Paste exported identity JSON here',
                                maxLines: 4,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Paste the full identity JSON exported from another device. Includes your private key.',
                                style: TextStyle(
                                  color: SecureColors.textSecondary,
                                  fontSize: 11.0,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: SecureColors.surfaceDarkSlate,
                                  ),
                                  foregroundColor: SecureColors.textSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onPressed: () async {
                                  final data =
                                      await Clipboard.getData('text/plain');
                                  if (data?.text != null) {
                                    _blobController.text = data!.text!;
                                  }
                                },
                                icon: const Icon(Icons.paste_outlined, size: 16),
                                label: const Text(
                                  'PASTE FROM CLIPBOARD',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.0,
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
                  ),

                  // Action Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        final isGenerate = _tabController.index == 0;
                        return TextButton(
                          onPressed: isLoading
                              ? null
                              : (isGenerate ? _generate : _import),
                          style: TextButton.styleFrom(
                            backgroundColor: SecureColors.textPrimary,
                            foregroundColor: SecureColors.background,
                            disabledBackgroundColor:
                                SecureColors.surfaceDarkSlate,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16.0),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        SecureColors.background),
                                  ),
                                )
                              : Text(
                                  isGenerate
                                      ? 'GENERATE IDENTITY'
                                      : 'IMPORT IDENTITY',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        );
                      },
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SecureColors.cryptoGreen, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: SecureColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 11.0,
            ),
          ),
        ),
      ],
    );
  }
}