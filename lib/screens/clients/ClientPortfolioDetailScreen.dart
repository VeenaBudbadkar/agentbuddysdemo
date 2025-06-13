import 'package:flutter/material.dart';

class ClientPortfolioDetailScreen extends StatelessWidget {
  final String clientName;

  const ClientPortfolioDetailScreen({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$clientName's Portfolio"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoRow("Name", clientName),
          _infoRow("Age", "45"),
          _infoRow("Relation", "Father"),
          _infoRow("Mobile", "+91 9876543210"),
          _infoRow("Email", "ramesh@example.com"),
          const SizedBox(height: 20),
          const Text("LIC Policies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _policyCard("Jeevan Anand", "₹10,00,000", "₹20,000/year", "Due: 01/09/2024"),
          _policyCard("New Endowment", "₹5,00,000", "₹15,000/year", "Due: 15/03/2025"),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("Download Report"),
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _policyCard(String title, String sumAssured, String premium, String due) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Sum Assured: $sumAssured"),
            Text("Premium: $premium"),
            Text("Next Due: $due"),
          ],
        ),
      ),
    );
  }
}
