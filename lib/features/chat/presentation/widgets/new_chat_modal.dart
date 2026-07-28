// lib/features/chat/presentation/widgets/new_chat_modal.dart
//
// LAYER: features/chat/presentation
// RESPONSIBILITY: UI for starting a new conversation.
//
// Accepts a contact address (public key fingerprint) via QR scan or manual
// text input. No IP address fallback. No P2P handshake. No Matrix room creation.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/addressing/contact_address.dart';
import '../../../../core/storage/storage_repository.dart';
import '../../../../theme/secure_colors.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../chat_room/presentation/screens/chat_room_screen.dart';

class NewChatModal extends StatefulWidget {
  /// The storage repository, injected from the parent context.
  final StorageRepository storage;

  const NewChatModal({super.key, required this.storage});

  static Future<void> show(BuildContext context, StorageRepository storage) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SecureColors.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (_) => NewChatModal(storage: storage),
    );
  }

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> {
  final TextEditingController _inputController = TextEditingController();
  MobileScannerController? _scannerController;
  bool? _hasPermission;
  String? _detectedAddress;
  bool _isValidAddress = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
    _requestCamera();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
        );
      });
    } else {
      setState(() => _hasPermission = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final addr = ContactAddress.fromShareBlob(raw);
    if (addr != null) {
      setState(() {
        _inputController.text = addr.fingerprint;
        _detectedAddress = addr.fingerprint;
        _isValidAddress = true;
      });
    } else {
      final trimmed = raw.trim();
      setState(() {
        _inputController.text = trimmed;
        _detectedAddress = trimmed;
        _isValidAddress = _isValidFingerprint(trimmed);
      });
    }
  }

  bool _isValidFingerprint(String value) {
    final re = RegExp(r'^[A-Za-z0-9_\-]{40,64}$');
    return re.hasMatch(value.trim());
  }

  Future<void> _openChat() async {
    final input = _inputController.text.trim();
    if (!_isValidFingerprint(input)) return;

    final contact = ContactAddress(fingerprint: input);
    await widget.storage.saveContact(contact);

    final conversation = Conversation(
      id: Conversation.idFor(input),
      contact: contact,
    );
    await widget.storage.saveConversation(conversation);

    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final input = _inputController.text.trim();
    final canOpen = _isValidFingerprint(input);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'NEW SECURE CONVERSATION',
                  style: TextStyle(
                    color: SecureColors.textPrimary,
                    fontFamily: 'Inter',
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'QR SCANNER',
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildViewfinder(),

                if (_detectedAddress != null) ...[
                  const SizedBox(height: 12),
                  _AddressChip(
                    address: _detectedAddress!,
                    isValid: _isValidAddress,
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'CONTACT ADDRESS (PUBLIC KEY)',
                  style: TextStyle(
                    color: SecureColors.textSecondary,
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                AuthTextField(
                  controller: _inputController,
                  hintText: 'Base64url fingerprint from contact',
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canOpen
                        ? SecureColors.cyberBlue
                        : SecureColors.surfaceDarkSlate,
                    foregroundColor: canOpen
                        ? SecureColors.background
                        : SecureColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0)),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: canOpen ? _openChat : null,
                  child: const Text(
                    'OPEN SECURE CHANNEL',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: SecureColors.background,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: SecureColors.surfaceDarkSlate, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Stack(
          children: [
            if (_hasPermission == null)
              const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
                ),
              )
            else if (_hasPermission == false)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'CAMERA ACCESS DENIED\nAllow camera in system settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SecureColors.textSecondary,
                      fontFamily: 'Inter',
                      fontSize: 11.0,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            else
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            if (_hasPermission == true) ..._corners(),
            if (_hasPermission == true) const _ScanLine(),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() => [
        _corner(top: 12, left: 12,
            border: const Border(top: BorderSide(color: SecureColors.cyberBlue, width: 2), left: BorderSide(color: SecureColors.cyberBlue, width: 2))),
        _corner(top: 12, right: 12,
            border: const Border(top: BorderSide(color: SecureColors.cyberBlue, width: 2), right: BorderSide(color: SecureColors.cyberBlue, width: 2))),
        _corner(bottom: 12, left: 12,
            border: const Border(bottom: BorderSide(color: SecureColors.cyberBlue, width: 2), left: BorderSide(color: SecureColors.cyberBlue, width: 2))),
        _corner(bottom: 12, right: 12,
            border: const Border(bottom: BorderSide(color: SecureColors.cyberBlue, width: 2), right: BorderSide(color: SecureColors.cyberBlue, width: 2))),
      ];

  Widget _corner({double? top, double? left, double? right, double? bottom, required Border border}) =>
      Positioned(
        top: top, left: left, right: right, bottom: bottom,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(border: border),
        ),
      );
}

class _AddressChip extends StatelessWidget {
  final String address;
  final bool isValid;

  const _AddressChip({required this.address, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final color = isValid ? SecureColors.cryptoGreen : SecureColors.panicRed;
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid
                  ? 'VALID: ${address.length > 12 ? "${address.substring(0, 12)}…" : address}'
                  : 'INVALID FORMAT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Positioned(
        top: _ctrl.value * 200,
        left: 12,
        right: 12,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: SecureColors.cyberBlue.withValues(alpha: 0.8),
            boxShadow: const [
              BoxShadow(
                color: SecureColors.cyberBlue,
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        ),
      ),
    );
  }
}