import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CashflowPdfHelper {
  static Future<Uint8List> generateBrandedPdf({
    required String clientName,
    required String planName,
    required List<Map<String, dynamic>> cashflowRows,
    required String agentName,
    required String agentPhone,
    Uint8List? agentPhotoBytes,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            if (logoBytes != null)
              pw.Image(pw.MemoryImage(logoBytes), width: 100),

            pw.SizedBox(height: 12),
            pw.Text('Cashflow Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Client: $clientName'),
            pw.Text('Plan: $planName'),
            pw.SizedBox(height: 20),

            _buildTable(cashflowRows),

            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (agentPhotoBytes != null)
                  pw.Image(pw.MemoryImage(agentPhotoBytes), width: 80, height: 80),

                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Agent: $agentName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Phone: $agentPhone'),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> rows) {
    final headers = rows.first.keys.toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: rows.map((row) => headers.map((h) => row[h].toString()).toList()).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
    );
  }
}
