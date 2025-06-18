import 'package:flutter/material.dart';
import 'package:agentbuddys/utils/agent_buddys_alerts.dart';

class GreetingsScreen extends StatelessWidget {
  const GreetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.cake, color: Colors.purple),
          title: const Text('🎂 Send Birthday Greetings'),
          onTap: () {
            Navigator.pushNamed(context, '/greetings/birthday');
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.red),
          title: const Text('💞 Send Anniversary Greetings'),
          onTap: () {
            Navigator.pushNamed(context, '/greetings/anniversary');
          },
        ),
        ListTile(
          leading: Icon(Icons.calendar_month, color: Colors.teal),
          title: const Text('📅 View Calendar & Automate'),
          onTap: () {
            Navigator.pushNamed(context, '/calendar');
          },
        ),
      ],
    );
  }
}