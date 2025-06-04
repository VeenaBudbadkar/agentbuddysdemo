import 'package:flutter/material.dart';
import 'package:agentbuddys/services/voice_limit_checker.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool isProcessing = false;
  String result = '';

  Future<void> handleVoiceCommand() async {
    setState(() {
      isProcessing = true;
      result = '';
    });

    final canProceed = await canUseVoiceAssistant(5); // Check for 5 mins usage

    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voice limit reached. Upgrade your plan.")),
      );
      setState(() => isProcessing = false);
      return;
    }

    // Simulate processing voice
    await Future.delayed(const Duration(seconds: 3));
    await logVoiceUsage(5); // Log 5 mins usage

    setState(() {
      isProcessing = false;
      result = 'Voice processed and 5 minutes logged!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Assistant"),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: isProcessing ? null : handleVoiceCommand,
                icon: const Icon(Icons.mic),
                label: const Text("Use Voice Assistant (5 min)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
              const SizedBox(height: 20),
              if (isProcessing) const CircularProgressIndicator(),
              if (result.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
