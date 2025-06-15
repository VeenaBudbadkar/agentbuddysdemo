import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppShareService {
  static final supabase = Supabase.instance.client;

  /// ✅ Upload PDF to Supabase Storage and get public link
  static Future<String> uploadPdfAndGetLink(Uint8List pdfBytes, String fileName) async {
    final bucket = 'cashflow_reports'; // Make sure this bucket exists
    final path = 'reports/$fileName';

    final response = await supabase.storage.from(bucket).uploadBinary(
      path,
      pdfBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    if (response.isEmpty) {
      throw Exception('❌ Upload failed');
    }

    // Make file public and get public URL
    final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// ✅ Share any text (or link) via WhatsApp
  static Future<void> shareText(String message) async {
    await Share.share(message);
  }
}
