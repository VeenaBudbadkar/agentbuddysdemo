import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> checkSubscriptionStatus() async {
  final supabase = Supabase.instance.client;
  final agentId = supabase.auth.currentUser?.id;
  if (agentId == null) return false;

  final result = await supabase
      .from('agent_subscriptions')
      .select('status, expiry_date')
      .eq('agent_id', agentId)
      .single();

  if (result == null || result['status'] != 'active') return false;

  final expiryDate = DateTime.tryParse(result['expiry_date']);
  return expiryDate != null && expiryDate.isAfter(DateTime.now());
}
