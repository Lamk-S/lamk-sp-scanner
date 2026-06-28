import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner POS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScannerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String status = 'Presiona el botón para escanear';
  bool isScanning = false;

  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool isProcessing = false;

  Future<bool> enviarCodigo(String codigo) async {
    // Modificar la URL de acuerdo a tu direccióm IP 
    const url = 'http://10.246.240.25:8000/api/scanner/push';

    try {
      print('Enviando a: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'codigo': codigo}),
      );

      print('STATUS => ${response.statusCode}');
      print('BODY => ${response.body}');

      return response.statusCode == 200;
    } catch (e, stack) {
      print('ERROR: $e');
      print(stack);
      return false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void iniciarScanner() {
    setState(() {
      isScanning = true;
      status = 'Apuntando al código...';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.start();
    });
  }

  Future<void> detenerScanner() async {
    await controller.stop();

    setState(() {
      isScanning = false;
      status = 'Escaneo cancelado.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pistola de Código POS'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: isScanning
                ? SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) async {
                        if (isProcessing) return;

                        final barcode = capture.barcodes.first;
                        final String? raw = barcode.rawValue;

                        if (raw == null) return;

                        isProcessing = true;

                        await controller.stop();

                        if (!mounted) return;

                        setState(() {
                          status =
                              'Código detectado: $raw\nEnviando a caja...';
                        });

                        bool ok = await enviarCodigo(raw);

                        if (!mounted) return;

                        setState(() {
                          isScanning = false;
                          status = ok
                              ? '✅ Enviado con éxito: $raw'
                              : '❌ Error de red al enviar: $raw';
                        });

                        isProcessing = false;
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (isScanning) {
            await detenerScanner();
          } else {
            iniciarScanner();
          }
        },
        icon: Icon(isScanning ? Icons.close : Icons.camera_alt),
        label: Text(isScanning ? 'Cancelar' : 'Escanear Producto'),
        backgroundColor: isScanning ? Colors.red : Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}