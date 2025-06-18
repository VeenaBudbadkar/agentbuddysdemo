import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AutoServices {
  final supabase = Supabase.instance.client;

  /// Call your Edge Function and show result as a Snackbar
  Future<void> callAutoScheduledServices(BuildContext context) async {
    try {
      final response = await supabase.functions.invoke(
        'auto_scheduled_services',
        body: {},
      );

      if (response.status != null && response.status! >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${response.data}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Success: ${response.data}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Exception: $e')),
      );
    }
  }
}
