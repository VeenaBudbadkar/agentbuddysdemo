import 'package:flutter/material.dart';

class AgentRankCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String branch;
  final String company;
  final String location;
  final String metric;
  final String value;

  const AgentRankCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.branch,
    required this.company,
    required this.location,
    required this.metric,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text("$name ($branch)", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$company | $location\n$metric: $value"),
      ),
    );
  }
}
