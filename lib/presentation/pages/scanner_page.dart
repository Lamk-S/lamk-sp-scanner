import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../data/services/scanner_service.dart';
import '../providers/scan_state.dart';
import '../widgets/scanner_overlay.dart';
import '../widgets/status_card.dart';
import '../widgets/scan_history_item.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with TickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final ScannerService _service;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  
  ScanState _state = const ScanState();
  final List<ScanState> _history = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _service = ScannerService();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.all],
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    _slideController.dispose();
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  void _updateState(ScanState newState) {
    if (_isDisposed) return;
    setState(() => _state = newState);
  }

  Future<void> _startScanning() async {
    _updateState(const ScanState(status: ScanStatus.scanning));
    try {
      await _controller.start();
    } catch (e) {
      _updateState(ScanState(
        status: ScanStatus.error,
        message: 'Error al iniciar cámara o permiso denegado',
      ));
    }
  }

  Future<void> _stopScanning() async {
    await _controller.stop();
    _updateState(const ScanState(status: ScanStatus.idle));
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // 1. Si no estamos activamente escaneando, ignoramos la cámara
    if (_state.status != ScanStatus.scanning) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // 2. Ya NO detenemos el controlador físico de la cámara.
    // Simplemente cambiamos el estado de la UI a "procesando".
    _updateState(ScanState(
      status: ScanStatus.processing,
      lastCode: raw,
      message: 'Enviando a caja...',
      lastScanTime: DateTime.now(),
    ));

    final result = await _service.sendBarcode(raw);

    if (_isDisposed) return;

    result.when(
      success: (_) {
        _addToHistory(true, raw);
        _updateState(ScanState(
          status: ScanStatus.success,
          lastCode: raw,
          message: 'Enviado con éxito',
          lastScanTime: DateTime.now(),
        ));
        HapticFeedback.mediumImpact();
        _showFeedbackSnack(true, raw);
      },
      failure: (msg) {
        _addToHistory(false, raw);
        _updateState(ScanState(
          status: ScanStatus.error,
          lastCode: raw,
          message: msg,
          lastScanTime: DateTime.now(),
        ));
        HapticFeedback.heavyImpact();
        _showFeedbackSnack(false, raw, msg);
      },
    );

    // 3. Volvemos al estado de escaneo sin reiniciar el hardware
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed && (_state.status == ScanStatus.success || _state.status == ScanStatus.error)) {
        _updateState(const ScanState(status: ScanStatus.scanning));
      }
    });
  }

  void _addToHistory(bool success, String code) {
    _history.insert(0, ScanState(
      status: success ? ScanStatus.success : ScanStatus.error,
      lastCode: code,
      lastScanTime: DateTime.now(),
    ));
    if (_history.length > 20) _history.removeLast();
  }

  void _showFeedbackSnack(bool success, String code, [String? error]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    success ? 'Producto registrado' : 'Error de envío',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    code,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  if (error != null)
                    Text(
                      error,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCameraActive = !_state.isIdle;

    return Scaffold(
      extendBodyBehindAppBar: isCameraActive,
      appBar: isCameraActive
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _stopScanning,
              ),
              title: Text(
                _getScannerTitle(), // Título dinámico
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : AppBar(
              title: const Text(AppConstants.appName),
              actions: [
                if (_history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: _showHistorySheet,
                    tooltip: 'Historial',
                  ),
              ],
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isCameraActive ? _buildScannerView() : _buildIdleView(),
      ),
      floatingActionButton: isCameraActive ? null : _buildMainFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getScannerTitle() {
    if (_state.isProcessing) return 'Procesando código...';
    if (_state.isSuccess) return '¡Código registrado!';
    if (_state.isError) return 'Error al enviar';
    return 'Apunta al código';
  }

  Widget _buildScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onBarcodeDetected,
          errorBuilder: (context, error) => _buildScannerError(error),
        ),
        ScannerOverlay(
          isProcessing: _state.isProcessing,
          pulseAnimation: _pulseController,
        ),
        if (_state.isProcessing)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Enviando...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdleView() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Logo/Icono animado
                  Hero(
                    tag: 'scanner-icon',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha:0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ScanNeo POS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea y envía productos a tu caja registradora',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  StatusCard(state: _state),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Últimos escaneos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._history.take(5).map((h) => ScanHistoryItem(state: h)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // Espacio para FAB
        ],
      ),
    );
  }

  Widget _buildMainFAB() {
    return FloatingActionButton.extended(
      onPressed: _startScanning,
      icon: const Icon(Icons.camera_alt),
      label: const Text(
        'Escanear Producto',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      elevation: 8,
    );
  }

  Widget _buildScannerError(MobileScannerException error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error de cámara',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error.errorCode.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Historial',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    // Botón de limpieza mejorado
                    if (_history.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                        tooltip: 'Limpiar historial',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Limpiar historial?'),
                              content: const Text('Se borrarán todos los registros locales. Esta acción no se puede deshacer.'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () {
                                    setState(() => _history.clear());
                                    Navigator.pop(ctx); // Cierra el diálogo
                                    Navigator.pop(context); // Cierra el BottomSheet
                                  },
                                  child: const Text('Limpiar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) => ScanHistoryItem(state: _history[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension helper para Result
extension ResultWhen<T> on Result<T> {
  void when({required void Function(T data) success, required void Function(String message) failure}) {
    switch (this) {
      case Success(data: final d): success(d);
      case Failure(message: final m): failure(m);
    }
  }
}