import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ExportService {
  static Future<void> exportTransactionsToCsv(List<Transaction> transactions) async {
    String csvData = 'ID,Date,Category,Amount,Type,Payment Method,Description,Mood\n';
    
    for (var tx in transactions) {
      csvData += '${tx.id},${tx.date},"${tx.category}",${tx.amount},${tx.type},"${tx.paymentMethod}","${tx.description.replaceAll('"', '""')}","${tx.mood}"\n';
    }

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/finwise_transactions_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    
    await file.writeAsString(csvData);
    
    await Share.shareXFiles([XFile(path)], text: 'My FinWise Transactions Export');
  }
}
