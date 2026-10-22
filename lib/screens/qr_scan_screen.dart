part of '../main.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR chấm công')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Hướng camera vào mã QR của Admin',
            ),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                if (scanned || capture.barcodes.isEmpty) {
                  return;
                }

                final qr =
                    capture.barcodes.first.rawValue;

                if (qr != null &&
                    qr.startsWith('HELLO-ATTENDANCE|')) {
                  scanned = true;
                  Navigator.pop(context, qr);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================
// TRANG ADMIN
// ====================================

