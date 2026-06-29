import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../providers/scan_state.dart';

class StatusCard extends StatelessWidget {
  final ScanState state;

  const StatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isIdle && state.lastCode == null) {
      return _buildWelcomeCard();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getBackgroundColor().withValues(alpha:0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 48,
            color: _getContentColor(),
          ),
          const SizedBox(height: 12),
          Text(
            _getTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getContentColor(),
            ),
          ),
          if (state.lastCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.lastCode!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _getContentColor(),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(
              state.message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _getContentColor().withValues(alpha:0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha:0.1), AppColors.primaryLight.withValues(alpha:0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.touch_app, size: 40, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Listo para escanear',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Presiona el botón para iniciar el escáner',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    return switch (state.status) {
      ScanStatus.success => AppColors.success.withValues(alpha:0.1),
      ScanStatus.error => AppColors.error.withValues(alpha:0.1),
      ScanStatus.processing => AppColors.info.withValues(alpha:0.1),
      _ => AppColors.surface,
    };
  }

  Color _getBorderColor() {
    return switch (state.status) {
      ScanStatus.success => AppColors.success,
      ScanStatus.error => AppColors.error,
      ScanStatus.processing => AppColors.info,
      _ => AppColors.border,
    };
  }

  Color _getContentColor() {
    return switch (state.status) {
      ScanStatus.success => AppColors.success,
      ScanStatus.error => AppColors.error,
      ScanStatus.processing => AppColors.info,
      _ => AppColors.textPrimary,
    };
  }

  IconData _getIcon() {
    return switch (state.status) {
      ScanStatus.success => Icons.check_circle,
      ScanStatus.error => Icons.error,
      ScanStatus.processing => Icons.sync,
      _ => Icons.qr_code,
    };
  }

  String _getTitle() {
    return switch (state.status) {
      ScanStatus.success => '¡Enviado correctamente!',
      ScanStatus.error => 'Error de envío',
      ScanStatus.processing => 'Procesando...',
      _ => 'Último escaneo',
    };
  }
}