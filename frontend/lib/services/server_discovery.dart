import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ServerDiscovery {
  /// Tries all known backend URLs in parallel and sets [ApiConstants.baseUrl]
  /// to the first one that responds successfully.
  /// Returns the working URL, or null if none responded.
  static Future<String?> findWorkingServer() async {
    debugPrint('🔍 ServerDiscovery: Scanning ${ApiConstants.knownBaseUrls.length} known addresses...');

    // Create a future for each known URL that resolves to the URL if it works
    final futures = ApiConstants.knownBaseUrls.map((url) async {
      try {
        final res = await http
            .get(Uri.parse('$url/fix-db')) // lightweight endpoint that always responds
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          debugPrint('✅ ServerDiscovery: Found working server at $url');
          return url;
        }
      } catch (_) {
        debugPrint('❌ ServerDiscovery: $url did not respond');
      }
      return null;
    }).toList();

    // Race all futures — use the first non-null result
    String? found;
    final results = await Future.wait(futures);
    for (final result in results) {
      if (result != null) {
        found = result;
        break;
      }
    }

    if (found != null) {
      ApiConstants.baseUrl = found;
      debugPrint('🎯 ServerDiscovery: Using $found');
    } else {
      debugPrint('⚠️  ServerDiscovery: No server found. Will use default: ${ApiConstants.baseUrl}');
    }

    return found;
  }
}
