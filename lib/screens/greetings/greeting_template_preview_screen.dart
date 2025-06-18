import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart'; // ✅ REQUIRED for RenderRepaintBoundary
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GreetingTemplatePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> template;
  final String clientName;
  final String agentName;

  const GreetingTemplatePreviewScreen({
    super.key,
    required this.template,
    required this.clientName,
    required this.agentName,
  });

  @override
  State<GreetingTemplatePreviewScreen> createState() =>
      _GreetingTemplatePreviewScreenState();
}

class _GreetingTemplatePreviewScreenState
    extends State<GreetingTemplatePreviewScreen> {
  final GlobalKey _previewKey = GlobalKey(); // ✅ RepaintBoundary key

  /// ✅ Share PNG
  Future<void> _shareAsImage() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final imagePath = '${dir.path}/greeting_card.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
        "🎉 ${widget.clientName}, best wishes from ${widget.agentName}! 🎉",
      );
    } catch (e) {
      debugPrint('❌ Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sharing greeting image')),
      );
    }
  }

  /// ✅ Download as PDF
  Future<void> _downloadAsPDF() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Image(pdfImage)),
        ),
      );

      final dir = await getTemporaryDirectory();
      final pdfPath = '${dir.path}/greeting_card.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ PDF saved to: $pdfPath')),
      );

      await OpenFilex.open(pdfPath);
    } catch (e) {
      debugPrint('❌ Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving greeting as PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Greeting Preview'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              RepaintBoundary(
                key: _previewKey, // ✅ native screenshot key
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      template['image_url'] ?? '',
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width * 0.9,
                    ),
                    Positioned(
                      bottom: 80,
                      child: Text(
                        widget.clientName,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Text(
                        "From ${widget.agentName}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                label: const Text('Send via WhatsApp (PNG)'),
                onPressed: _shareAsImage,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download as PDF (optional)'),
                onPressed: _downloadAsPDF,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
