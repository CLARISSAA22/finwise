import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class UpiService {
  static const MethodChannel _channel = MethodChannel('com.finwise/upi');

  /// Launches Android's native UPI intent chooser.
  /// Returns the raw response string from the UPI app, or null if it couldn't launch.
  static Future<String?> launchUpiPayment({
    required double amount,
    required String upiId,
    String? upiName,
    String? note,
  }) async {
    final payeeName = Uri.encodeComponent(upiName ?? 'Recipient');
    final txNote = Uri.encodeComponent(note ?? 'FinWise Payment');

    // Generate a unique transaction reference (required by many banks for deep links)
    final tr = 'FIN${DateTime.now().millisecondsSinceEpoch}';

    // User requested to remove auto-fill and just open the payment app dashboard natively
    final String uriStr = 'upi://pay';

    try {
      final String? result = await _channel.invokeMethod('launchUpi', {'uri': uriStr});
      return result;
    } on PlatformException catch (e) {
      debugPrint('UPI launch error: ${e.message}');
      return null;
    }
  }

  /// Converts a 10-digit phone number to common UPI IDs to try.
  /// Returns the most likely UPI ID based on common bank handles.
  static String phoneToUpiId(String phone) {
    // Most common UPI handles in India
    // We use @ybl (PhonePe) as the default since it has highest adoption
    return '$phone@ybl';
  }

  /// All common UPI handles for a phone number
  static List<String> phoneToAllUpiIds(String phone) {
    return [
      '$phone@ybl',       // PhonePe
      '$phone@okicici',   // GPay (ICICI)
      '$phone@oksbi',     // GPay (SBI)
      '$phone@okaxis',    // GPay (Axis)
      '$phone@okhdfcbank',// GPay (HDFC)
      '$phone@paytm',     // Paytm
      '$phone@apl',       // Amazon Pay
    ];
  }
}
