import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:matrix/matrix.dart' as matrix;
import '../../../../theme/secure_colors.dart';
import '../../../auth/data/matrix_auth_service.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';

class NewChatModal extends StatefulWidget {
  const NewChatModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SecureColors.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (context) => const NewChatModal(),
    );
  }

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> {
  late final TextEditingController _matrixIdController;
  MobileScannerController? _scannerController;
  bool? _hasPermission;
  String? _errorMessage;
  String? _detectedId;
  bool _isValidFormat = false;
  bool _isProcessingHandshake = false;

  @override
  void initState() {
    super.initState();
    _matrixIdController = TextEditingController();
    _matrixIdController.addListener(_onTextChanged);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _matrixIdController.removeListener(_onTextChanged);
    _matrixIdController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
        );
      });
    } else {
      setState(() {
        _hasPermission = false;
        _errorMessage = "Camera access denied. Permit camera use in settings.";
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        String parsedId = rawValue.trim();

        if (parsedId.startsWith('matrix:u/')) {
          final stripped = parsedId.replaceFirst('matrix:u/', '');
          parsedId = !stripped.startsWith('@') ? '@$stripped' : stripped;
        }

        final regExp = RegExp(r'^@[a-zA-Z0-9_\-\.\=\/]+:[a-zA-Z0-9_\-\.]+\.[a-zA-Z]+');
        if (regExp.hasMatch(parsedId) || parsedId.startsWith('@')) {
          setState(() {
            _matrixIdController.text = parsedId;
            _detectedId = parsedId;
            _isValidFormat = true;
          });
        } else {
          setState(() {
            _detectedId = parsedId;
            _isValidFormat = false;
          });
        }
      }
    }
  }

  Future<void> _executeSecureHandshake(String remoteMatrixId) async {
    setState(() => _isProcessingHandshake = true);
    final authService = Provider.of<MatrixAuthService>(context, listen: false);

    try {
      // Execute the live room creation method calling standard Matrix endpoints.
      // This instantiates a trusted, private DM channel and auto-invites Client B.
      await authService.client.createRoom(
        invite: [remoteMatrixId],
        isDirect: true,
        preset: matrix.CreateRoomPreset.trustedPrivateChat,
        visibility: matrix.Visibility.private,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SecureColors.surfaceCharcoal,
            content: Text(
              "SECURE LINK OPENED // CHANNEL SYNCHRONIZED",
              style: TextStyle(color: SecureColors.cryptoGreen, fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingHandshake = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A0505),
            content: Text(
              "HANDSHAKE FAILED // ${e.toString()}",
              style: const TextStyle(color: SecureColors.panicRed, fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }
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
                  valueColor: AlwaysStoppedAnimation<Color>(SecureColors.cyberBlue),
                ),
              )
            else if (_hasPermission == false)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: SecureColors.panicRed, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        "CAMERA_ACCESS_DENIED",
                        style: TextStyle(
                          color: SecureColors.panicRed,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? "Allow camera access inside system settings.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: SecureColors.textSecondary, fontSize: 11.0, height: 1.4),
                      ),
                    ],
                  ),
                ),
              )
            else
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            if (_hasPermission == true) ...[
              Positioned(
                top: 12, left: 12,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: SecureColors.cyberBlue, width: 2.0), left: BorderSide(color: SecureColors.cyberBlue, width: 2.0)))),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: SecureColors.cyberBlue, width: 2.0), right: BorderSide(color: SecureColors.cyberBlue, width: 2.0)))),
              ),
              Positioned(
                bottom: 12, left: 12,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SecureColors.cyberBlue, width: 2.0), left: BorderSide(color: SecureColors.cyberBlue, width: 2.0)))),
              ),
              Positioned(
                bottom: 12, right: 12,
                child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SecureColors.cyberBlue, width: 2.0), right: BorderSide(color: SecureColors.cyberBlue, width: 2.0)))),
              ),
              const _ScanLineAnimation(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isButtonEnabled = _matrixIdController.text.trim().isNotEmpty && !_isProcessingHandshake;

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
                  "INITIALIZE_NEW_SECURE_LINK",
                  style: TextStyle(color: SecureColors.textPrimary, fontFamily: 'Inter', fontSize: 14.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 20),
                const Text(
                  "SECURE_QR_SCANNER",
                  style: TextStyle(color: SecureColors.textSecondary, fontFamily: 'Inter', fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                _buildViewfinder(),
                if (_detectedId != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: _isValidFormat ? SecureColors.cryptoGreen.withOpacity(0.08) : SecureColors.panicRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: _isValidFormat ? SecureColors.cryptoGreen : SecureColors.panicRed, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(_isValidFormat ? Icons.check_circle_outline : Icons.error_outline, color: _isValidFormat ? SecureColors.cryptoGreen : SecureColors.panicRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isValidFormat ? "QR_RESOLVED: $_detectedId" : "INVALID_MATRIX_ID_FORMAT: $_detectedId",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11.0, fontWeight: FontWeight.bold, color: _isValidFormat ? SecureColors.cryptoGreen : SecureColors.panicRed),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  "MANUAL_MATRIX_ID_HANDSHAKE",
                  style: TextStyle(color: SecureColors.textSecondary, fontFamily: 'Inter', fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                AuthTextField(
                  controller: _matrixIdController,
                  hintText: "@user:homeserver",
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled ? SecureColors.cyberBlue : SecureColors.surfaceDarkSlate,
                    foregroundColor: isButtonEnabled ? SecureColors.background : SecureColors.textSecondary,
                    disabledBackgroundColor: SecureColors.surfaceDarkSlate,
                    disabledForegroundColor: SecureColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  onPressed: isButtonEnabled
                      ? () => _executeSecureHandshake(_matrixIdController.text.trim())
                      : null,
                  child: _isProcessingHandshake
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(SecureColors.background),
                          ),
                        )
                      : const Text(
                          "INITIATE_SECURE_LINK",
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13.0),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Positioned(
          top: _animController.value * 200,
          left: 12,
          right: 12,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: SecureColors.cyberBlue.withOpacity(0.8),
              boxShadow: const [BoxShadow(color: SecureColors.cyberBlue, blurRadius: 4.0, spreadRadius: 1.0)],
            ),
          ),
        );
      },
    );
  }
}