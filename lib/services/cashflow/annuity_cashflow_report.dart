import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cashflow_pdf_helper.dart';

import 'package:agentbuddys/utils/annuity_engine.dart';
import 'package:agentbuddys/utils/pdf_helper.dart';
import 'package:agentbuddys/utils/whatsapp_share_service.dart';


class AnnuityCashflowReportScreen extends StatefulWidget {
  final String planId;
  final double purchaseAmount;
  final String annuityOption;

  const AnnuityCashflowReportScreen({
    super.key,
    required this.planId,
    required this.purchaseAmount,
    required this.annuityOption,
  });

  @override
  State<AnnuityCashflowReportScreen> createState() =>
      _AnnuityCashflowReportScreenState();
}

class _AnnuityCashflowReportScreenState
    extends State<AnnuityCashflowReportScreen> {
  double? finalRate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    calculateAnnuity();
  }

  Future<void> calculateAnnuity() async {
    try {
      final annuityEngine = AnnuityEngine(Supabase.instance.client);
      final rate = await annuityEngine.getFinalAnnuityRate(
        planId: widget.planId,
        purchaseAmount: widget.purchaseAmount,
        annuityOption: widget.annuityOption,
      );

      setState(() {
        finalRate = rate;
        isLoading = false;
      });

      debugPrint("🔥 Annuity Rate: ${rate.toStringAsFixed(2)}%");
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadPdf() async {
    if (finalRate == null) return;

    final pdfBytes = await PdfHelper.generateAnnuityPdf(
      planId: widget.planId,
      purchaseAmount: widget.purchaseAmount,
      annuityOption: widget.annuityOption,
      finalRate: finalRate!,
    );

    await PdfHelper.savePdfToDevice(pdfBytes, 'AnnuityReport.pdf');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ PDF saved!')),
    );
  }

  Future<void> shareOnWhatsApp() async {
    if (finalRate == null) return;

    final pdfBytes = await PdfHelper.generateAnnuityPdf(
      planId: widget.planId,
      purchaseAmount: widget.purchaseAmount,
      annuityOption: widget.annuityOption,
      finalRate: finalRate!,
    );

    final downloadLink = await WhatsAppShareService.uploadPdfAndGetLink(
      pdfBytes,
      'AnnuityReport.pdf',
    );

    await WhatsAppShareService.shareText(
      '📄 Here is your Annuity Report: $downloadLink',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuity Cashflow Report"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "✅ Plan: ${widget.planId}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "💰 Purchase Amount: ₹${widget.purchaseAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "📈 Option: ${widget.annuityOption}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "🔥 Final Annuity Rate: ${finalRate!.toStringAsFixed(2)}%",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download PDF"),
                ),
                ElevatedButton.icon(
                  onPressed: shareOnWhatsApp,
                  icon: const Icon(Icons.share),
                  label: const Text("Share WhatsApp"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
