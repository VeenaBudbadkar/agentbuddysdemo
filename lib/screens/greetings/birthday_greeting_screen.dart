import 'package:flutter/material.dart';

class BirthdayGreetingScreen extends StatefulWidget {
  const BirthdayGreetingScreen({super.key});

  @override
  State<BirthdayGreetingScreen> createState() => _BirthdayGreetingScreenState();
}

class _BirthdayGreetingScreenState extends State<BirthdayGreetingScreen> {
  List<Client> birthdayClients = [
    Client(name: 'Snehalata Bhosale', dob: '01 Jun', age: 35, category: 'VIP'),
    Client(name: 'Amit Sharma', dob: '01 Jun', age: 40, category: 'HNI'),
    Client(name: 'Veena Kulkarni', dob: '01 Jun', age: 29, category: 'Family')
  ];

  List<bool> selectedClients = [];
  int selectedTemplateIndex = 0;

  @override
  void initState() {
    selectedClients = List.filled(birthdayClients.length, false);
    super.initState();
  }

  void sendManually() {
    final selected = birthdayClients
        .asMap()
        .entries
        .where((e) => selectedClients[e.key])
        .map((e) => e.value.name)
        .toList();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Manual Send'),
        content: Text('Send greetings manually to: ${selected.join(', ')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void sendAutomatically() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Automatic Send'),
        content: const Text('50 credits will be used. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AutomationConfirmationPage(),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget buildTemplatePicker() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() => selectedTemplateIndex = index),
          child: Container(
            width: 100,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: selectedTemplateIndex == index ? Colors.deepPurple : Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Center(child: Text('🎉 T-${index + 1}')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎂 Today's Birthdays")),
      body: Column(
      children: [
        Expanded(
        child: ListView.builder(
        itemCount: birthdayClients.length,
        itemBuilder: (context, index) {
          final client = birthdayClients[index];
          return CheckboxListTile(
            value: selectedClients[index],
            onChanged: (val) => setState(() => selectedClients[index] = val!),
            title: Text(client.name),
            subtitle: Text('${client.dob} • Age ${client.age} • ${client.category}'),
          );
        },
      ),
      ),
      const Divider(),
      buildTemplatePicker(),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: sendManually,
              icon: const Icon(Icons.send),
              label: const Text('Send Selected Manually (Free)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sendAutomatically,
              icon: const Icon(Icons.flash_on),
              label: const Text('Send All Automatically – 50 Credits'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
          ],
        ),
      )
      ],
    ),
    );
  }
}

class Client {
  final String name;
  final String dob;
  final int age;
  final String category;

  Client({required this.name, required this.dob, required this.age, required this.category});
}

class AutomationConfirmationPage extends StatelessWidget {
  const AutomationConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Activate Monthly Automation For:', style: TextStyle(fontWeight: FontWeight.bold)),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('🎂 Birthdays')),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('💍 Anniversaries')),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('🏖️ Important Days')),
          CheckboxListTile(value: false, onChanged: (_) {}, title: const Text('💰 Premium Reminders')),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.verified),
            label: const Text('Activate Automation Package'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}
