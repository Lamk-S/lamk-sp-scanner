import 'package:flutter/material.dart';
import 'presentation/pages/scanner_page.dart';
import 'core/theme/app_theme.dart';

class ScannerApp extends StatelessWidget {
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanNeo POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ScannerPage(),
    );
  }
}