// File: top_performers_section.dart

import 'package:flutter/material.dart';

class TopPerformersSection extends StatelessWidget {
  final List<Map<String, dynamic>> topNOP;
  final List<Map<String, dynamic>> topPremium;

  const TopPerformersSection({
    super.key,
    required this.topNOP,
    required this.topPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            '🏆 Top NOP Performers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildPerformerList(topNOP, 'NOP'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            '💰 Top Premium Performers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildPerformerList(topPremium, 'Premium'),
      ],
    );
  }

  Widget _buildPerformerList(List<Map<String, dynamic>> performers, String type) {
    final medals = ['🥇', '🥈', '🥉'];

    return Column(
      children: List.generate(performers.length, (index) {
        final performer = performers[index];
        final name = performer['name'] ?? 'Unknown';
        final branch = performer['branch_code'] ?? '';
        final company = performer['company'] ?? 'LIC';
        final city = performer['city'] ?? 'N/A';
        final value = performer[type.toLowerCase()] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            leading: Text(
              medals[index],
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(
              '$name ($branch)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$company – $city'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type == 'NOP' ? '$value NOP' : '₹$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
