import 'package:flutter/material.dart';

class FilteredClientListScreen extends StatelessWidget {
  final String triggerKey;
  final List<dynamic> filteredClients;

  const FilteredClientListScreen({
    super.key,
    required this.triggerKey,
    required this.filteredClients,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Use filteredClients in your UI
    return Scaffold(
      appBar: AppBar(title: Text("Filtered: $triggerKey")),
      body: ListView.builder(
        itemCount: filteredClients.length,
        itemBuilder: (context, index) {
          final client = filteredClients[index];
          return ListTile(
            title: Text(client['first_name'] ?? 'No Name'),
            subtitle: Text(client['contact_number'] ?? ''),
          );
        },
      ),
    );
  }
}
