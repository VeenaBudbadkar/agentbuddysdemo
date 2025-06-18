import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Use this to show a custom snackbar OR branded upsell dialog.
/// If [showUpsell] is true, shows upgrade popup with auto-deduct logic.

class AgentBuddysAlerts {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

void showAgentBuddysAlert(
    BuildContext context, {
      required String message,
      bool isError = false,
      bool showUpsell = false,
    }) {
  if (showUpsell) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🚀 Go Automatic!"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;
                if (user == null) {
                  // Not logged in — handle accordingly
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Please login first")),
                  );
                  return;
                }

                // 1️⃣ Deduct 99 credits from agent_credits table (example)
                final creditResponse = await supabase
                    .from('agent_credits')
                    .update({'credits': supabase.rpc('subtract_credits', params: {
                  'agent_id': user.id,
                  'amount': 99,
                })})
                    .eq('agent_id', user.id);

                // 2️⃣ Enable automation flag
                final autoResponse = await supabase
                    .from('agent_automation_settings')
                    .upsert({
                  'agent_id': user.id,
                  'automation_enabled': true,
                  'auto_credit_pack': 99,
                });

                // 3️⃣ Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Automation enabled for 30 days!"),
                    backgroundColor: Colors.green,
                  ),
                );

                // ✅ Optional: navigate to Dashboard
                // Navigator.of(context).pushReplacementNamed('/dashboard');
              },
              child: const Text("✅ Go Automatic"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("❌ Maybe Later"),
            ),
          ],
        );
      },
    );
  } else {
    final color = isError ? Colors.red : Colors.green;
    final icon = isError ? Icons.error : Icons.check_circle;

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
