import 'package:supabase_flutter/supabase_flutter.dart';

/// Check if agent has enough voice assistant minutes left
Future<bool> canUseVoiceAssistant(int minutesToUse) async {
  final supabase = Supabase.instance.client;
  final agentId = supabase.auth.currentUser?.id;
  if (agentId == null) return false;

  // Fetch active subscription
  final sub = await supabase
      .from('agent_subscriptions')
      .select('plan_name, expiry_date')
      .eq('agent_id', agentId)
      .eq('status', 'active')
      .maybeSingle();

  if (sub == null) return false;

  final expiry = DateTime.tryParse(sub['expiry_date']);
  if (expiry == null || expiry.isBefore(DateTime.now())) return false;

  final plan = sub['plan_name'];
  final limit = {
    'Smart': 15,
    'Power': 20,
    'Elite': 30,
  }[plan] ?? 0;

  final today = DateTime.now().toIso8601String().split('T')[0];

  // Fetch today's usage
  final usage = await supabase
      .from('agent_voice_usage')
      .select('minutes_used')
      .eq('agent_id', agentId)
      .eq('date', today)
      .maybeSingle();

  final used = usage?['minutes_used'] ?? 0;
  final remaining = limit - used;

  return remaining >= minutesToUse;
}

/// Update the voice usage log after assistant is used
Future<void> logVoiceUsage(int minutesUsed) async {
  final supabase = Supabase.instance.client;
  final agentId = supabase.auth.currentUser?.id;
  if (agentId == null) return;

  final today = DateTime.now().toIso8601String().split('T')[0];

  // Check existing entry
  final existing = await supabase
      .from('agent_voice_usage')
      .select('minutes_used')
      .eq('agent_id', agentId)
      .eq('date', today)
      .maybeSingle();

  final used = existing?['minutes_used'] ?? 0;

  // Insert or update usage
  await supabase.from('agent_voice_usage').upsert({
    'agent_id': agentId,
    'date': today,
    'minutes_used': used + minutesUsed,
  }, onConflict: 'agent_id, date');
}
