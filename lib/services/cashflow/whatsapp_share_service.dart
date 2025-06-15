import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart'; // ✅ For FileOptions
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart'; // ✅ For snackbars if needed

class WhatsAppShareService {
  static final supabase = Supabase.instance.client;

  /// ✅ Upload, try signed URL, fallback to public URL, log all.
  static Future<String> uploadPdfAndGetRobustUrl(
      Uint8List pdfBytes,
      String fileName, {
        int expirySeconds = 86400, // default: 24 hrs
      }) async {
    final bucket = 'cashflow_reports';
    final path = 'reports/$fileName';

    try {
      // Upload with upsert
      final response = await supabase.storage.from(bucket).uploadBinary(
        path,
        pdfBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      if (response.isEmpty) {
        throw Exception('❌ Upload failed: empty response');
      }

      debugPrint('✅ Upload done: $path');

      // Try signed URL
      final signedUrl = await supabase.storage.from(bucket).createSignedUrl(path, expirySeconds);

      debugPrint('✅ Signed URL created: $signedUrl');
      return signedUrl;

    } catch (e) {
      debugPrint('⚠️ Signed URL failed: $e');

      // Fallback to public URL
      try {
        final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
        debugPrint('⚠️ Fallback to public URL: $publicUrl');
        return publicUrl;
      } catch (e2) {
        debugPrint('❌ Fallback failed too: $e2');
        throw Exception('Failed to get a valid URL. Please try again.');
      }
    }
  }

  /// ✅ Share link on WhatsApp with smart text
  static Future<void> shareLinkOnWhatsApp({
    required String link,
    required String clientName,
    required String agentName,
    required String agentPhone,
    BuildContext? context, // optional for snackbar
  }) async {
    try {
      final message = """
Hi $clientName 👋,

Please find your personalized Cashflow Report prepared by $agentName.
👉 Download here (valid link): $link

For any help, reach me at $agentPhone.

Thank you!
""";
      await Share.share(message);
      debugPrint('✅ WhatsApp link share sent.');
    } catch (e) {
      debugPrint('❌ Link share error: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing link: $e')),
        );
      }
    }
  }

  /// ✅ Direct file share — with logs & snackbar
  static Future<void> sharePdfFile(
      Uint8List pdfBytes,
      String fileName,
      String message, {
        BuildContext? context,
      }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
      );

      debugPrint('✅ PDF file shared directly.');
    } catch (e) {
      debugPrint('❌ PDF file share error: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing file: $e')),
        );
      }
    }
  }
}
