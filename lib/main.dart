import 'package:flutter/material.dart';
import 'services/scan_state.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PortScanApp());
}

class PortScanApp extends StatelessWidget {
  const PortScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '端口扫描工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: HomePage(scanState: ScanState()),
    );
  }
}