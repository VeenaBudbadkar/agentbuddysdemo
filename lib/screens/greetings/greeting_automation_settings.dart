import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/agent_buddys_alerts.dart';
import 'package:agentbuddys/utils/agent_buddys_alerts.dart';

class GreetingAutomationSetting extends StatefulWidget {
  const GreetingAutomationSetting({super.key});

  @override
  State<GreetingAutomationSetting> createState() => _GreetingAutomationSettingState();
}

class _GreetingAutomationSettingState extends State<GreetingAutomationSetting> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool automationEnabled = false;

  @override
  void initState() {
    super.initState();
    loadAutomationStatus();
  }

  Future<void> loadAutomationStatus() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('agent_automation_settings')
          .select('greetings_enabled')
          .eq('agent_id', userId)
          .single();

      setState(() {
        automationEnabled = response['greetings_enabled'] ?? false;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('❌ Error loading automation status: $error');
      AgentBuddysAlerts.showError(context, 'Failed to load automation settings.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateAutomationStatus(bool value) async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      final existing = await supabase
          .from('agent_automation_settings')
          .select()
          .eq('agent_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        await supabase
            .from('agent_automation_settings')
            .update({'greetings_enabled': value})
            .eq('agent_id', userId);
      } else {
        // Insert new record
        await supabase.from('agent_automation_settings').insert({
          'agent_id': userId,
          'greetings_enabled': value,
        });
      }

      setState(() {
        automationEnabled = value;
      });

      AgentBuddysAlerts.showSuccess(context,
          value ? 'Greeting automation enabled!' : 'Greeting automation disabled!');
    } catch (error) {
      debugPrint('❌ Error updating automation status: $error');
      AgentBuddysAlerts.showError(context, 'Failed to update automation settings.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greeting Automation'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automatic Greetings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable this to automatically send birthday & anniversary greetings to your clients without manual effort.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Automation',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: automationEnabled,
                  onChanged: (value) {
                    updateAutomationStatus(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
