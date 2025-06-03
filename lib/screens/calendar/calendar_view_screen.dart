import 'package:flutter/material.dart';

class CalendarViewScreen extends StatelessWidget {
  const CalendarViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📅 Calendar View')),
      body: const Center(child: Text('Calendar & Automation Features')),
    );
  }
}
