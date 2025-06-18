import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agentbuddys/utils/agent_buddys_alerts.dart';
import 'package:agentbuddys/services/upgrade_flow_service.dart';

class GreetingsTriggerSettings extends StatefulWidget {
  const GreetingsTriggerSettings({super.key});

  @override
  State<GreetingsTriggerSettings> createState() =>
      _GreetingsTriggerSettingsState();
}

class _GreetingsTriggerSettingsState extends State<GreetingsTriggerSettings> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool automationEnabled = false;

  @override
  void initState() {
    super.initState();
    loadAutomationStatus();
  }



// Example: Check credits BEFORE enabling automation
  Future<void> updateAutomationStatus(bool value) async {
    setState(() => isLoading = true);

    if (value) {
      // If turning ON → check credits first!
      final canProceed = await UpgradeFlowService.checkCreditsAndPrompt(
        context: context,
        creditsRequired: 99,
      );
      if (!canProceed) {
        setState(() => isLoading = false);
        return; // Stop toggle
      }
    }

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('agent_automation_settings').upsert({
        'agent_id': userId,
        'automation_enabled': value,
      });

      setState(() {
        automationEnabled = value;
        isLoading = false;
      });

      showAgentBuddysAlert(
        context,
        message: value
            ? '✅ Automation ENABLED!'
            : '⚙️ Automation DISABLED.',
      );
    } catch (error) {
      setState(() => isLoading = false);
      showAgentBuddysAlert(context, message: 'Error: $error', isError: true);
    }
  }

  Future<void> loadAutomationStatus() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        showAgentBuddysAlert(
          context,
          message: '❌ Please log in first.',
          isError: true,
        );
        return;
      }

      final response = await supabase
          .from('agent_automation_settings')
          .select('automation_enabled')
          .eq('agent_id', userId)
          .maybeSingle();

      setState(() {
        automationEnabled = response != null && response['automation_enabled'] == true;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      showAgentBuddysAlert(
        context,
        message: 'Could not load status: $error',
        isError: true,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greeting Automation Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Auto-Scheduled Greetings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Automation',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: automationEnabled,
                  onChanged: (value) => updateAutomationStatus(value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'When enabled, your birthday, anniversary, and premium reminders '
                  'will be automatically sent based on your credits and plan.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
