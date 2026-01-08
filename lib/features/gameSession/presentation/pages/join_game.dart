import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/main.dart' show apiBaseUrl;

import '../controllers/multiplayer_session_controller.dart';
import 'player_lobby_screen.dart';
import '../../../report/presentation/pages/reports_list_page.dart';

const _defaultNickname = 'Jugador';

/// Pantalla para que el jugador ingrese PIN/QR y se una a una partida.
class JoinGameScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const JoinGameScreen({super.key, this.scrollController});

  @override
  State<JoinGameScreen> createState() => JoinGameScreenState();
}

class JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isJoining = false;
  bool _canSubmitPin = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_handlePinChanged);
  }

  /// Habilita/deshabilita CTA cuando el PIN tiene formato válido.
  void _handlePinChanged() {
    final nextState = _isValidPin(_pinController.text);
    if (nextState != _canSubmitPin) {
      setState(() => _canSubmitPin = nextState);
    }
  }

  /// Valida que el PIN sea numérico de 6-10 dígitos.
  bool _isValidPin(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 6 || trimmed.length > 10) {
      return false;
    }
    for (var i = 0; i < trimmed.length; i++) {
      final codeUnit = trimmed.codeUnitAt(i);
      if (codeUnit < 48 || codeUnit > 57) {
        return false;
      }
    }
    return true;
  }

  /// Normaliza nickname y aplica fallback si es muy corto.
  String _resolveNickname(String? rawNickname) {
    final trimmed = rawNickname?.trim() ?? '';
    if (trimmed.length >= 6) {
      return trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    }
    return _defaultNickname;
  }

  /// Intenta unirse a la sala con el PIN ingresado.
  Future<void> onEnterPinPressed() async {
    final pin = _pinController.text.trim();
    if (!_isValidPin(pin)) {
      _showSnack('Ingresa un PIN de 6 a 10 dígitos para continuar');
      return;
    }

    setState(() => _isJoining = true);
    final sessionController = context.read<MultiplayerSessionController>();

    try {
      final nickname = _resolveNickname(sessionController.currentNickname);
      await sessionController
          .joinLobby(pin: pin, nickname: nickname)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La sala no respondió, verifica el PIN.');
      });
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PlayerLobbyScreen()));
    } catch (error) {
      if (!mounted) return;
      await _showErrorDialog(
        title: 'No se pudo unir',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  /// Lanza hoja inferior con escáner de QR (resuelve PIN).
  void onScanQrPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: _QrScannerSheet(
          onCloseRequested: () => Navigator.of(sheetContext).pop(),
          onPinResolved: (pin) {
            setState(() => _pinController.text = pin);
            Navigator.of(sheetContext).pop();
            _showSnack('PIN detectado automáticamente');
          },
        ),
      ),
    );
  }

  /// Helper para mostrar mensajes en snackbar.
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showErrorDialog({required String title, required String message}) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.removeListener(_handlePinChanged);
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerGap = (size.height * 0.06).clamp(24.0, 80.0);
    final actionGap = (size.height * 0.08).clamp(24.0, 96.0);

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
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

                  SizedBox(height: headerGap),

                  // Contenido Principal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      autofocus: false,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Ingresa el PIN que aparece en la pantalla del anfitrión (6-10 dígitos).',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Botón temporal para navegar a la lista de reportes (solo para QA/preview).
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.onPrimary,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportsListPage(
                            baseUrl: apiBaseUrl,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment_outlined),
                    label: const Text('Ver reportes (temporal)'),
                  ),

                  SizedBox(height: actionGap),

                  // Botones Abajo
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        // Boton "Introduzca PIN"
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isJoining || !_canSubmitPin
                                ? null
                                : onEnterPinPressed,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: AppColor.secundary,
                              foregroundColor: AppColor.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.grid_view_rounded, size: 22),
                            label: _isJoining
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrScannerSheet extends StatefulWidget {
  final VoidCallback onCloseRequested;
  final ValueChanged<String> onPinResolved;

  const _QrScannerSheet({
    required this.onCloseRequested,
    required this.onPinResolved,
  });

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  late final MobileScannerController _controller;
  bool _torchOn = false;
  bool _isProcessingToken = false;
  bool _hasResolvedPin = false;

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
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
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

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (!mounted || _isProcessingToken || _hasResolvedPin) return;
    final token = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
    if (token == null) return;

    setState(() => _isProcessingToken = true);
    try {
      final controller = context.read<MultiplayerSessionController>();
      final pin = await controller.resolvePinFromQrToken(token.trim());
      if (!mounted) return;
      _hasResolvedPin = true;
      widget.onPinResolved(pin);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener el PIN: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingToken = false);
      }
    }
  }
}
