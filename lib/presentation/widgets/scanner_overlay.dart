import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ScannerOverlay extends StatelessWidget {
  final bool isProcessing;
  final AnimationController pulseAnimation;

  const ScannerOverlay({
    super.key,
    required this.isProcessing,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 280,
      height: 280,
    );

    return CustomPaint(
      size: Size.infinite,
      painter: _ScannerOverlayPainter(
        scanWindow: scanWindow,
        borderColor: isProcessing ? AppColors.success : AppColors.scannerFrame,
        pulseAnimation: pulseAnimation,
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;
  final AnimationController pulseAnimation;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = AppColors.scannerOverlay
      ..style = PaintingStyle.fill;

    // Dibujar fondo oscuro con "agujero" para el scan window
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()..addRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
    );
    
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, cutout),
      backgroundPaint,
    );

    // Dibujar esquinas del scanner
    final cornerPaint = Paint()
      ..color = borderColor.withValues(alpha:0.5 + 0.5 * pulseAnimation.value)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;

    // Esquina superior izquierda
    _drawCorner(canvas, scanWindow.topLeft, cornerLength, cornerPaint, true, true);
    // Esquina superior derecha
    _drawCorner(canvas, scanWindow.topRight, cornerLength, cornerPaint, false, true);
    // Esquina inferior izquierda
    _drawCorner(canvas, scanWindow.bottomLeft, cornerLength, cornerPaint, true, false);
    // Esquina inferior derecha
    _drawCorner(canvas, scanWindow.bottomRight, cornerLength, cornerPaint, false, false);

    // Línea láser animada
    final laserPaint = Paint()
      ..color = AppColors.error.withValues(alpha:0.6 * pulseAnimation.value)
      ..strokeWidth = 2;

    final laserY = scanWindow.top + scanWindow.height * (0.3 + 0.4 * pulseAnimation.value);
    canvas.drawLine(
      Offset(scanWindow.left + 10, laserY),
      Offset(scanWindow.right - 10, laserY),
      laserPaint,
    );
  }

  void _drawCorner(Canvas canvas, Offset corner, double length, Paint paint, bool left, bool top) {
    final path = Path();
    if (left && top) {
      path.moveTo(corner.dx + length, corner.dy);
      path.lineTo(corner.dx + 10, corner.dy);
      path.arcToPoint(Offset(corner.dx, corner.dy + 10), radius: const Radius.circular(10));
      path.lineTo(corner.dx, corner.dy + length);
    } else if (!left && top) {
      path.moveTo(corner.dx - length, corner.dy);
      path.lineTo(corner.dx - 10, corner.dy);
      path.arcToPoint(Offset(corner.dx, corner.dy + 10), radius: const Radius.circular(10), clockwise: false);
      path.lineTo(corner.dx, corner.dy + length);
    } else if (left && !top) {
      path.moveTo(corner.dx + length, corner.dy);
      path.lineTo(corner.dx + 10, corner.dy);
      path.arcToPoint(Offset(corner.dx, corner.dy - 10), radius: const Radius.circular(10), clockwise: false);
      path.lineTo(corner.dx, corner.dy - length);
    } else {
      path.moveTo(corner.dx - length, corner.dy);
      path.lineTo(corner.dx - 10, corner.dy);
      path.arcToPoint(Offset(corner.dx, corner.dy - 10), radius: const Radius.circular(10));
      path.lineTo(corner.dx, corner.dy - length);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) => true;
}