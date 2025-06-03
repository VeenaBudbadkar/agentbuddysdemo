import 'package:flutter/material.dart';

class AnniversaryGreetingScreen extends StatelessWidget {
  const AnniversaryGreetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💞 Anniversary Greetings')),
      body: const Center(child: Text('Anniversary Greetings UI will go here')),
    );
  }
}
