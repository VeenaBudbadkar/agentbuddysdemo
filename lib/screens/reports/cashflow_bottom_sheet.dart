import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:agentbuddys/utils/annuity_engine.dart';
import '../../services/cashflow/cashflow_generator.dart';
import '../../services/cashflow/cashflow_pdf_helper.dart';
import '../../services/cashflow/whatsapp_share_service.dart';

class CashflowReportBottomSheet extends StatefulWidget {
  final String policyId;
  final String clientName;
  final String planName;
  final String agentName;
  final String agentPhone;

  const CashflowReportBottomSheet({
    super.key,
    required this.policyId,
    required this.clientName,
    required this.planName,
    required this.agentName,
    required this.agentPhone,
  });

  @override
  State<CashflowReportBottomSheet> createState() =>
      _CashflowReportBottomSheetState();
}

class _CashflowReportBottomSheetState
    extends State<CashflowReportBottomSheet> {
  late Future<List<Map<String, dynamic>>> _cashflowFuture;
  Uint8List? _pdfBytes;

  bool _pdfReady = false;

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

    setState(() {
      _pdfReady = true; // ✅ Trigger success tick
    });
  }

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
        context: context,
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
            label: Text(h,
                style: const TextStyle(fontWeight: FontWeight.bold))))
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Column(
              children: [
                // Fancy Drag Handle
                Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // 🎉 Hero Cashflow Animation
                SizedBox(
                  height: 100,
                  child: Lottie.asset(
                    'assets/lottie/cashflow_hero.json',
                    repeat: true,
                  ),
                ),
                // ✅ Optional Success Tick if PDF generated
                if (_pdfReady)
                  SizedBox(
                    height: 60,
                    child: Lottie.asset(
                      'assets/lottie/success_tick.json',
                      repeat: false,
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _cashflowFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('❌ Error: ${snapshot.error}'));
                      }

                      final rows = snapshot.data!;

                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "📄 Cashflow Report",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(height: 300, child: _buildTable(rows)),
                            const SizedBox(height: 20),

                            // 👤 Advisor Avatar Lottie
                            SizedBox(
                              height: 100,
                              child: Lottie.asset(
                                'assets/lottie/advisor.json',
                                repeat: true,
                              ),
                            ),

                            ElevatedButton.icon(
                              onPressed: () => _shareSignedLink(rows),
                              icon: const Icon(Icons.link),
                              label:
                              const Text('Auto Upload + Signed Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize:
                                const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _shareDirectFile(rows),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Share PDF Directly'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize:
                                const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

