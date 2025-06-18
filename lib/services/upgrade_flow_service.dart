import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/agent_buddys_alerts.dart';

class UpgradeFlowService {
  static final supabase = Supabase.instance.client;

  /// Checks if agent has enough credits, else shows upsell
  static Future<bool> checkCreditsAndPrompt({
    required BuildContext context,
    required int creditsRequired,
  }) async {
    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) {
      showAgentBuddysAlert(context, message: '❌ Not logged in.', isError: true);
      return false;
    }

    final profile = await supabase
        .from('agent_profile')
        .select('credit_balance')
        .eq('agent_id', agentId)
        .single();

    final balance = profile['credit_balance'] ?? 0;

    if (balance >= creditsRequired) {
      return true; // Enough credits, proceed.
    } else {
      showAgentBuddysAlert(
        context,
        message:
        '🚫 Not enough credits ($balance) — You need $creditsRequired.\nUpgrade to continue.',
        showUpsell: true,
      );
      return false;
    }
  }

  /// Deduct credits after successful operation
  static Future<void> deductCredits({
    required int creditsToDeduct,
  }) async {
    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) return;

    await supabase.rpc('deduct_credits', params: {
      'agent_id': agentId,
      'amount': creditsToDeduct,
    });
  }

  /// Example upgrade redirect (adjust as needed)
  static void goToUpgradePage(BuildContext context) {
    // TODO: Implement your in-app upgrade/payment flow or redirect
    showAgentBuddysAlert(
      context,
      message: '🚀 Opening payment page...',
    );
  }
}
