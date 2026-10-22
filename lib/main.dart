import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';


part 'config/api_config.dart';
part 'services/api_client.dart';
part 'utils/app_helpers.dart';
part 'screens/login_screen.dart';
part 'screens/employee_screen.dart';
part 'screens/qr_scan_screen.dart';
part 'screens/admin_screen.dart';
part 'screens/motion_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HelloCheckIn());
}

class HelloCheckIn extends StatelessWidget {
  const HelloCheckIn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hello CheckIn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      ),
      home: const LoginScreen(),
    );
  }
}

// ====================================
// ĐĂNG KÝ - ĐĂNG NHẬP - OTP
// ====================================

