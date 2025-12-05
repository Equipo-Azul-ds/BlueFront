import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:Trivvy/core/constants/colors.dart';
import '../mocks/mock_session_data.dart';
import 'player_lobby_screen.dart';
import 'host_lobby.dart';

class JoinGameScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const JoinGameScreen({super.key, this.scrollController});

  @override
  State<JoinGameScreen> createState() => JoinGameScreenState();
}

class JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController _pinController = TextEditingController();

  void onEnterPinPressed() {
    final pin = _pinController.text.trim().isEmpty
        ? mockSessionPin
        : _pinController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerLobbyScreen(
          nickname: mockDefaultNickname,
          pinCode: pin,
        ),
      ),
    );
  }

  // Vista de cámara puramente visual por ahora
  void onScanQrPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: _QrScannerSheet(
          onCloseRequested: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary, AppColor.secundary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Boton Cerrar: close the modal/page
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColor.onPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    // Titulo
                    const Text(
                      "Unirse a un juego",
                      style: TextStyle(
                        color: AppColor.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 32, height: 32),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.06),

              // Contenido Principal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _pinController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.onPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  // Cursor
                  cursorColor: AppColor.accent,
                  cursorHeight: 64,
                  cursorWidth: 3,
                  decoration: InputDecoration(
                    hintText: 'PIN',
                    hintStyle: TextStyle(
                      color: AppColor.onPrimary.withValues(alpha: 0.35),
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: false,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Botones Abajo
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Row(
                  children: [
                    // Boton "Introduzca PIN"
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEnterPinPressed,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColor.secundary,
                          foregroundColor: AppColor.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.grid_view_rounded,
                          size: 22,
                        ),
                        label: const Text(
                          "Introduzca PIN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Boton "Escanear codigo QR"
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onScanQrPressed,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColor.accent,
                          foregroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 22),
                        label: const Text(
                          "Escanear Codigo QR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HostLobbyScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pantallas Host',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

class _QrScannerSheet extends StatefulWidget {
  final VoidCallback onCloseRequested;

  const _QrScannerSheet({required this.onCloseRequested});

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  late final MobileScannerController _controller;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      torchEnabled: _torchOn,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (_) {},
          ),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: widget.onCloseRequested,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 72.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Escáner pronto disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Mantén el QR dentro del recuadro',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white70, width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _controller.switchCamera(),
                  child: const Icon(Icons.cameraswitch),
                ),
                const SizedBox(width: 16),
                FilledButton.tonal(
                  onPressed: _toggleTorch,
                  child: Icon(_torchOn ? Icons.flash_off : Icons.flash_on),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
