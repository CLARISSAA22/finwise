import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSettingPin;
  final VoidCallback onSuccess;

  const PinLockScreen({super.key, this.isSettingPin = false, required this.onSuccess});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _storage = const FlutterSecureStorage();
  String _inputPin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  String _error = '';

  void _handleNumber(String n) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += n;
        _error = '';
      });
      if (_inputPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _backspace() {
    if (_inputPin.isNotEmpty) {
      setState(() => _inputPin = _inputPin.substring(0, _inputPin.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    if (widget.isSettingPin) {
      if (!_isConfirming) {
        setState(() {
          _firstPin = _inputPin;
          _inputPin = '';
          _isConfirming = true;
        });
      } else {
        if (_inputPin == _firstPin) {
          await _storage.write(key: 'app_pin', value: _inputPin);
          widget.onSuccess();
        } else {
          setState(() {
            _inputPin = '';
            _error = 'PINs do not match. Try again.';
          });
        }
      }
    } else {
      final storedPin = await _storage.read(key: 'app_pin');
      if (_inputPin == storedPin) {
        widget.onSuccess();
      } else {
        setState(() {
          _inputPin = '';
          _error = 'Incorrect PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.isSettingPin 
        ? (_isConfirming ? 'Confirm your PIN' : 'Set a New PIN')
        : 'Enter your PIN';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, color: Colors.white, size: 64),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _inputPin.length ? Colors.white : Colors.white24,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              )),
            ),
            const Spacer(),
            // Numpad
            _buildNumpad(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['1', '2', '3'].map(_buildNumBtn).toList()),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['4', '5', '6'].map(_buildNumBtn).toList()),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['7', '8', '9'].map(_buildNumBtn).toList()),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty
            _buildNumBtn('0'),
            SizedBox(
              width: 80,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 32),
                onPressed: _backspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumBtn(String n) {
    return SizedBox(
      width: 80,
      height: 80,
      child: InkWell(
        onTap: () => _handleNumber(n),
        borderRadius: BorderRadius.circular(40),
        child: Center(child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
