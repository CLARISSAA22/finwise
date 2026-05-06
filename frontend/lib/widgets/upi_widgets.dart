import 'package:flutter/material.dart';

class UpiAppPicker extends StatelessWidget {
  final Function(bool) onSelect;

  const UpiAppPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> upiApps = [
      {
        'name': 'GPay',
        'color': const Color(0xFF4285F4),
        'icon': 'https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/google-pay-icon.png'
      },
      {
        'name': 'PhonePe',
        'color': const Color(0xFF5f259f),
        'icon': 'https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/phonepe-icon.png'
      },
      {
        'name': 'Paytm',
        'color': const Color(0xFF00baf2),
        'icon': 'https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/paytm-icon.png'
      },
      {
        'name': 'Amazon',
        'color': const Color(0xFFff9900),
        'icon': 'https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/amazon-pay-icon.png'
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: upiApps.map((app) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(true),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: app['color'].withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: app['color'].withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        app['icon'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.payment, color: app['color'], size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['name'],
                    style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
