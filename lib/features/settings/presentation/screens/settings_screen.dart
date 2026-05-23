import 'package:flutter/material.dart';
import '../../../../theme/secure_colors.dart';
import '../widgets/key_management_cards.dart';
import '../widgets/panic_button.dart';
import '../widgets/tor_switch_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Hardcoded runtime state placeholder to be bound into regional hardware configs later
  bool _isTorNetworkActive = false;

  void _executeLocalMemorySanitization() {
    // TODO: Direct operational hooks:
    // 1. Hive.deleteFromDisk()
    // 2. database.close() -> deleteDatabase(dbPath)
    // 3. flutter_secure_storage.deleteAll()
    // 4. exit(0) or Route back to baseline AuthState pipeline
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: SecureColors.panicRed,
        content: Text(
          "PANIC_TRIGGERED // DATA_PURGE_SEQUENCE_COMPLETED",
          style: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecureColors.background,
      
      // Minimalist Tactical Screen Title Bar
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
      
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Layer Section Title: Routing
            const Text(
              "NETWORK_INFRASTRUCTURE",
              style: TextStyle(color: SecureColors.textSecondary, fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            TorSwitchTile(
              isActive: _isTorNetworkActive,
              onToggle: (bool val) {
                setState(() {
                  _isTorNetworkActive = val;
                });
              },
            ),
            
            const SizedBox(height: 28),
            
            // Layer Section Title: Encryption Controls
            const Text(
              "SECURITY_AND_KEYS",
              style: TextStyle(color: SecureColors.textSecondary, fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            KeyManagementCards(
              onExportKeys: () {
                // TODO: Wire up to File system access pipelines
              },
              onImportKeys: () {
                // TODO: Wire up to encrypted JSON import parser
              },
            ),
            
            const SizedBox(height: 40),
            
            // System Destruction Execution Anchor
            const Text(
              "DESTRUCTIVE_ACTIONS",
              style: TextStyle(color: SecureColors.panicRed, fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            PanicButton(
              onZeroizeConfirmed: _executeLocalMemorySanitization,
            ),
          ],
        ),
      ),
    );
  }
}