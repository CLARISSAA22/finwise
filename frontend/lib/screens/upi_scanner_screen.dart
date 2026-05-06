import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'add_transaction_screen.dart';

class UpiScannerScreen extends StatefulWidget {
  const UpiScannerScreen({super.key});

  @override
  State<UpiScannerScreen> createState() => _UpiScannerScreenState();
}

class _UpiScannerScreenState extends State<UpiScannerScreen> {
  bool _isProcessed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessed) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('upi://pay')) {
        setState(() => _isProcessed = true);
        _parseAndNavigate(code);
        break;
      }
    }
  }

  void _parseAndNavigate(String upiUri) {
    final uri = Uri.parse(upiUri);
    final params = uri.queryParameters;

    final String? upiId = params['pa'];
    final String? name = params['pn'];
    final String? amountStr = params['am'];
    final String? note = params['tn'];

    double? amount;
    if (amountStr != null) {
      amount = double.tryParse(amountStr);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialAmount: amount,
          initialDescription: note ?? (name != null ? "Pay to $name" : null),
          initialUpiId: upiId,
          initialUpiName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan UPI QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
            onDetect: _onDetect,
          ),
          // Viewfinder Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Point camera at a UPI QR code',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
