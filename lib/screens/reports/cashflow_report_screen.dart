import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../../services/cashflow/cashflow_generator.dart';
import '../../services/cashflow/cashflow_pdf_helper.dart';
import '../../services/cashflow/whatsapp_share_service.dart';

class CashflowReportScreen extends StatefulWidget {
  final String policyId;
  final String clientName;
  final String planName;
  final String agentName;
  final String agentPhone;

  const CashflowReportScreen({
    super.key,
    required this.policyId,
    required this.clientName,
    required this.planName,
    required this.agentName,
    required this.agentPhone,
  });

  @override
  State<CashflowReportScreen> createState() => _CashflowReportScreenState();
}

class _CashflowReportScreenState extends State<CashflowReportScreen> {
  late Future<List<Map<String, dynamic>>> _cashflowFuture;
  Uint8List? _pdfBytes; // ✅ Cache for reuse

  @override
  void initState() {
    super.initState();
    _cashflowFuture = _loadCashflow();
  }

  Future<List<Map<String, dynamic>>> _loadCashflow() async {
    final generator = CashflowGenerator(Supabase.instance.client);
    return await generator.generate(widget.policyId);
  }

  Future<void> _generatePdf(List<Map<String, dynamic>> rows) async {
    _pdfBytes = await CashflowPdfHelper.generateBrandedPdf(
      clientName: widget.clientName,
      planName: widget.planName,
      cashflowRows: rows,
      agentName: widget.agentName,
      agentPhone: widget.agentPhone,
    );
  }

  /// ✅ Robust signed link share (with fallback)
  Future<void> _shareSignedLink(List<Map<String, dynamic>> rows) async {
    try {
      if (_pdfBytes == null) await _generatePdf(rows);

      final robustUrl = await WhatsAppShareService.uploadPdfAndGetRobustUrl(
        _pdfBytes!,
        '${widget.clientName.replaceAll(" ", "_")}_Cashflow.pdf',
      );

      await WhatsAppShareService.shareLinkOnWhatsApp(
        link: robustUrl,
        clientName: widget.clientName,
        agentName: widget.agentName,
        agentPhone: widget.agentPhone,
        context: context, // ✅ so snackbars show
      );
    } catch (e) {
      debugPrint('❌ _shareSignedLink failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// ✅ Direct PDF file share
  Future<void> _shareDirectFile(List<Map<String, dynamic>> rows) async {
    try {
      if (_pdfBytes == null) await _generatePdf(rows);

      final message = """
Hi ${widget.clientName} 👋,

Please find your personalized Cashflow Report prepared by ${widget.agentName}.

For any help, reach me at ${widget.agentPhone}.

Thank you!
""";

      await WhatsAppShareService.sharePdfFile(
        _pdfBytes!,
        '${widget.clientName.replaceAll(" ", "_")}_Cashflow.pdf',
        message,
        context: context,
      );
    } catch (e) {
      debugPrint('❌ _shareDirectFile failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildTable(List<Map<String, dynamic>> rows) {
    final headers = rows.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers
            .map((h) => DataColumn(
            label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold))))
            .toList(),
        rows: rows
            .map((row) => DataRow(
          cells: headers
              .map((h) => DataCell(Text(row[h].toString())))
              .toList(),
        ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashflow Report'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cashflowFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          final rows = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTable(rows),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _shareSignedLink(rows),
                      icon: const Icon(Icons.link),
                      label: const Text('Auto Upload + Signed Link (Robust)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _shareDirectFile(rows),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Share PDF Directly'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
