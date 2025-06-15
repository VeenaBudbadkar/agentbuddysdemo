import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfHelper {
  /// ✅ Generates a simple annuity PDF
  static Future<Uint8List> generateAnnuityPdf({
    required String planId,
    required double purchaseAmount,
    required String annuityOption,
    required double finalRate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('📄 Annuity Report', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Plan ID: $planId'),
            pw.Text('Purchase Amount: ₹${purchaseAmount.toStringAsFixed(2)}'),
            pw.Text('Option: $annuityOption'),
            pw.Text('Final Annuity Rate: ${finalRate.toStringAsFixed(2)}%'),
            pw.SizedBox(height: 20),
            pw.Text('Thank you for choosing AgentBuddys!'),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// ✅ Saves PDF to device (Downloads directory or app files)
  static Future<void> savePdfToDevice(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
