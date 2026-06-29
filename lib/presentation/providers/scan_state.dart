enum ScanStatus { idle, scanning, processing, success, error }

class ScanState {
  final ScanStatus status;
  final String? lastCode;
  final String? message;
  final DateTime? lastScanTime;

  const ScanState({
    this.status = ScanStatus.idle,
    this.lastCode,
    this.message,
    this.lastScanTime,
  });

  ScanState copyWith({
    ScanStatus? status,
    String? lastCode,
    String? message,
    DateTime? lastScanTime,
  }) {
    return ScanState(
      status: status ?? this.status,
      lastCode: lastCode ?? this.lastCode,
      message: message ?? this.message,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }

  bool get isScanning => status == ScanStatus.scanning;
  bool get isProcessing => status == ScanStatus.processing;
  bool get isSuccess => status == ScanStatus.success;
  bool get isError => status == ScanStatus.error;
  bool get isIdle => status == ScanStatus.idle;
}