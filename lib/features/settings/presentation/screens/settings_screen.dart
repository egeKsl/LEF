import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/transport/transport_adapter.dart';
import '../../../../theme/secure_colors.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/key_management_cards.dart';
import '../widgets/panic_button.dart';
import '../widgets/tor_switch_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _relayUrlController;
  late final TextEditingController _relayTokenController;

  @override
  void initState() {
    super.initState();
    _relayUrlController = TextEditingController();
    _relayTokenController = TextEditingController();
    context.read<SettingsBloc>().add(LoadSettingsRequested());
  }

  @override
  void dispose() {
    _relayUrlController.dispose();
    _relayTokenController.dispose();
    super.dispose();
  }

  Color _getConnectionColor(TransportConnectionState state) {
    switch (state) {
      case TransportConnectionState.connected:
        return SecureColors.cryptoGreen;
      case TransportConnectionState.connecting:
      case TransportConnectionState.disconnecting:
        return SecureColors.cyberBlue;
      case TransportConnectionState.disconnected:
        return SecureColors.textSecondary;
      case TransportConnectionState.error:
        return SecureColors.panicRed;
    }
  }

  String _getConnectionText(TransportConnectionState state) {
    switch (state) {
      case TransportConnectionState.connected:
        return "CONNECTED // ACTIVE";
      case TransportConnectionState.connecting:
        return "CONNECTING...";
      case TransportConnectionState.disconnecting:
        return "DISCONNECTING...";
      case TransportConnectionState.disconnected:
        return "DISCONNECTED";
      case TransportConnectionState.error:
        return "CONNECTION ERROR";
    }
  }

  void _handleExportKeys(BuildContext context) {
    context.read<SettingsBloc>().add(ExportIdentityRequested());
  }

  void _handleImportKeys(BuildContext context) {
    final TextEditingController importController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: SecureColors.surfaceCharcoal,
          title: const Text(
            "IMPORT_CRYPTOGRAPHIC_KEYS",
            style: TextStyle(
              color: SecureColors.textPrimary,
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Paste your exported identity payload string below:",
                style: TextStyle(color: SecureColors.textSecondary, fontSize: 11.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: importController,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11.0,
                  color: SecureColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Paste Base64 identity payload or JSON',
                  hintStyle: TextStyle(color: SecureColors.textSecondary, fontSize: 11.0),
                  fillColor: SecureColors.background,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: SecureColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final payload = importController.text.trim();
                if (payload.isNotEmpty) {
                  context.read<SettingsBloc>().add(ImportIdentityRequested(payload));
                }
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "IMPORT",
                style: TextStyle(color: SecureColors.cyberBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog(BuildContext context, String payload) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SecureColors.surfaceCharcoal,
          title: const Text(
            "EXPORT_CRYPTOGRAPHIC_KEYS",
            style: TextStyle(
              color: SecureColors.textPrimary,
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: SecureColors.background,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: SecureColors.surfaceDarkSlate),
                ),
                child: SelectableText(
                  payload,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11.0,
                    color: SecureColors.cyberBlue,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payload));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: SecureColors.surfaceCharcoal,
                    content: Text(
                      "KEYS_COPIED_TO_CLIPBOARD",
                      style: TextStyle(color: SecureColors.cryptoGreen, fontFamily: 'Inter'),
                    ),
                  ),
                );
              },
              child: const Text("COPY_TO_CLIPBOARD", style: TextStyle(color: SecureColors.cyberBlue)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: SecureColors.textPrimary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      appBar: AppBar(
        backgroundColor: SecureColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: SecureColors.textPrimary, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NODE_CONFIG_SETTINGS",
          style: TextStyle(
            color: SecureColors.textPrimary,
            fontFamily: 'Inter',
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: SecureColors.surfaceCharcoal, width: 1.0)),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.isPurged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: SecureColors.panicRed,
                content: Text(
                  "PANIC_TRIGGERED // DATA_PURGE_SEQUENCE_COMPLETED",
                  style: TextStyle(
                    color: SecureColors.textPrimary,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.auth,
              (route) => false,
            );
          } else if (state.exportedPayload != null) {
            _showExportDialog(context, state.exportedPayload!);
          } else if (state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: SecureColors.surfaceCharcoal,
                content: Text(
                  state.statusMessage!,
                  style: const TextStyle(color: SecureColors.cyberBlue, fontFamily: 'Inter'),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (_relayUrlController.text.isEmpty && state.relayUrl.isNotEmpty) {
            _relayUrlController.text = state.relayUrl;
          }
          if (_relayTokenController.text.isEmpty && state.relayToken.isNotEmpty) {
            _relayTokenController.text = state.relayToken;
          }

          final connColor = _getConnectionColor(state.connectionState);
          final connText = _getConnectionText(state.connectionState);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "RELAY_SERVER_CONFIGURATION",
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: SecureColors.surfaceCharcoal,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: SecureColors.surfaceDarkSlate),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: connColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "STATUS: $connText",
                            style: TextStyle(
                              color: connColor,
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relayUrlController,
                        style: const TextStyle(
                          color: SecureColors.textPrimary,
                          fontFamily: 'Inter',
                          fontSize: 13.0,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'wss://relay.example.com',
                          hintStyle: TextStyle(color: SecureColors.textSecondary, fontSize: 13.0),
                          prefixIcon: Icon(Icons.dns_outlined, color: SecureColors.textSecondary, size: 18),
                          filled: true,
                          fillColor: SecureColors.background,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _relayTokenController,
                        obscureText: true,
                        style: const TextStyle(
                          color: SecureColors.textPrimary,
                          fontFamily: 'Inter',
                          fontSize: 13.0,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'bootstrap token',
                          hintStyle: TextStyle(color: SecureColors.textSecondary, fontSize: 13.0),
                          prefixIcon: Icon(Icons.verified_user_outlined, color: SecureColors.textSecondary, size: 18),
                          filled: true,
                          fillColor: SecureColors.background,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SecureColors.cyberBlue,
                          foregroundColor: SecureColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        onPressed: () {
                          context.read<SettingsBloc>().add(
                                UpdateRelayUrlRequested(_relayUrlController.text),
                              );
                            context.read<SettingsBloc>().add(
                              UpdateRelayTokenRequested(_relayTokenController.text),
                            );
                        },
                        child: const Center(
                          child: Text(
                            "APPLY RELAY CONFIG",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "NETWORK_INFRASTRUCTURE",
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TorSwitchTile(
                  isActive: state.isTorEnabled,
                  onToggle: (bool val) {
                    context.read<SettingsBloc>().add(ToggleTorRequested(val));
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  "SECURITY_AND_KEYS",
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                KeyManagementCards(
                  onExportKeys: () => _handleExportKeys(context),
                  onImportKeys: () => _handleImportKeys(context),
                ),

                const SizedBox(height: 40),

                const Text(
                  "DESTRUCTIVE_ACTIONS",
                  style: TextStyle(
                    color: SecureColors.panicRed,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                PanicButton(
                  onZeroizeConfirmed: () {
                    context.read<SettingsBloc>().add(ExecutePanicPurgeRequested());
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}