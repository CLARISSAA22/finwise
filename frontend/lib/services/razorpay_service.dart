import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String description,
    String? email,
    String? contact,
    String? orderId,
  }) {
    var options = {
      'key': ApiConstants.razorpayKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'FinWise',
      'order_id': orderId,
      'description': description,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
        'method': 'upi',
        'vpa': ApiConstants.senderUpiId, // ✅ Pre-filling your sender UPI ID
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
