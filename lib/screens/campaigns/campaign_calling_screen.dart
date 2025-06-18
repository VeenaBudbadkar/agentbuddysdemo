import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CampaignCallingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> leads;

  const CampaignCallingScreen({super.key, required this.leads});

  @override
  State<CampaignCallingScreen> createState() => _CampaignCallingScreenState();
}

class _CampaignCallingScreenState extends State<CampaignCallingScreen> {
  int currentIndex = 0;

  void _callCurrentLead() async {
    final lead = widget.leads[currentIndex];
    final number = lead['contact_number'];
    final url = Uri.parse("tel:$number");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not launch dialer")),
      );
    }
  }

  void _whatsappCurrentLead() async {
    final lead = widget.leads[currentIndex];
    final number = lead['contact_number'];
    final url = Uri.parse("https://wa.me/$number");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not launch WhatsApp")),
      );
    }
  }

  void _nextLead() {
    if (currentIndex < widget.leads.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Campaign Completed!")),
      );
      Navigator.pop(context); // Back to Lead List
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leads.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No leads to call!")),
      );
    }

    final lead = widget.leads[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("📞 Calling Campaign"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Lead ${currentIndex + 1} of ${widget.leads.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              lead['name'] ?? "No Name",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              lead['contact_number'] ?? "No Number",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _callCurrentLead,
              icon: const Icon(Icons.call),
              label: const Text("Call Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _whatsappCurrentLead,
              icon: const Icon(Icons.message), // or Icons.chat, or Icons.send
              label: const Text("WhatsApp Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _nextLead,
              child: const Text("Next Lead"),
            ),
          ],
        ),
      ),
    );
  }
}
