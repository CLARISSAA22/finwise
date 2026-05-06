import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E88E5);     
   // Trust Blue- App bar, buttons, active navigation icons, links
  static const Color secondary = Color(0xFF43A047);    
  // Growth Green -Income indicators, success messages, saving badges, positive trends
  static const Color accent = Color(0xFFFB8C00);       
  // Alert Orange (Warning) - Expenditure indicators, warnings, overdue alerts
  static const Color error = Color(0xFFE53935);       
   // Danger Red - Critical errors, overspending, negative alerts  
  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);   
  // Soft Gray (Light)- Dashboard, screens
  static const Color backgroundDark = Color(0xFF1E1E2E); 
  // Dark Slate (Future dark mode)- Login, settings (where we want contrast)
  static const Color cardColor = Color(0xFFFFFFFF);   
   // White- Cards, dialogs, active surfaces
  
  // Typography
  static const Color textDark = Color(0xFF212121);    
   // Dark Gray (Primary text)- Headings, amounts, strong text
  static const Color textLight = Color(0xFF757575);    
  // Medium Gray (Secondary text)- Subtitles, descriptions, disabled text
  
  // UI Elements
  static const Color divider = Color(0xFFE0E0E0);     
   // Light Gray- Dividers, borders
  
  // Maintained for backward compatibility in specific layouts
  static const Color primaryLight = Color(0xFFBBDEFB); 
  // Extra Light Blue - Pastels for charts and graphs
  static const Color secondaryLight = Color(0xFFC8E6C9);
    // Extra Light Green - Pastels for charts and graphs

  static List<BoxShadow> shadow = [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
  ];
  static BorderRadius borderRadius = BorderRadius.circular(20);
}

class ApiConstants {
  static const List<String> knownBaseUrls = [
    'http://192.168.1.5:5000',
    'http://192.168.137.104:5000',
    'http://10.210.67.128:5000',
    'http://172.16.10.35:5000',
    'http://10.174.168.128:5000', 
    'http://192.168.1.4:5000',  
    'http://localhost:5000',    
    'http://10.0.2.2:5000',
    'http://192.168.137.6:5000',  
  ];
  static String baseUrl = knownBaseUrls.first;

  // UPI Configuration
  static const String upiId = '9019266938@naviaxis'; 
  static const String senderUpiId = '9110437937-h239@ibl'; 
  static const String upiName = 'Merlin Maria S';
  static const String razorpayKey = 'rzp_test_SeRVcJY7WqBcIT'; 
}
class DateFormatter {
  static String format(String raw) {
    if (raw.isEmpty) return raw;
    try {
      if (raw.length > 10) {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw);
        return DateFormat('dd-MM-yyyy HH:mm').format(dt);
      } else {
        final dt = DateFormat('yyyy-MM-dd').parse(raw);
        return DateFormat('dd-MM-yyyy').format(dt);
      }
    } catch (_) {
      return raw;
    }
  }
}
