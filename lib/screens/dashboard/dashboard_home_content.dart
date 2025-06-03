import 'package:flutter/material.dart';

class DashboardHomeContent extends StatelessWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.cake, color: Colors.purple),
          title: const Text('🎂 Birthdays Today'),
          onTap: () {
            Navigator.pushNamed(context, '/greetings/birthday');
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.redAccent),
          title: const Text('💞 Anniversaries Today'),
          onTap: () {
            Navigator.pushNamed(context, '/greetings/anniversary');
          },
        ),
        ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.teal),
          title: const Text('📅 Calendar View'),
          onTap: () {
            Navigator.pushNamed(context, '/calendar');
          },
        ),
      ],
    );
  }
}
