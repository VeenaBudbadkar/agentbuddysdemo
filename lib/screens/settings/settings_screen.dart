import 'package:flutter/material.dart';
import 'package:agentbuddys/screens/monetization/credit_store_screen.dart';
import 'package:agentbuddys/screens/subscription/subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Account'),
            subtitle: Text('Manage your profile and preferences'),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Buy Credits'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreditStoreScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Subscription Plans'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
