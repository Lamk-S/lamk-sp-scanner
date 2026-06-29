import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';

class ScannerService {
  final http.Client _client;
  
  ScannerService({http.Client? client}) : _client = client ?? http.Client();

  Future<Result<bool>> sendBarcode(String code) async {
    final url = '${AppConstants.apiBaseUrl}/api/scanner/push';
    
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'codigo': code}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure(
          'Error del servidor: ${response.statusCode}',
          error: response.body,
        );
      }
    } on Exception catch (e, stack) {
      return Failure(
        'Error de conexión. Verifica tu red.',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void dispose() => _client.close();
}