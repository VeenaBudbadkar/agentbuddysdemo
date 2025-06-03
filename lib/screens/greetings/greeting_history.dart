import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GreetingHistory extends StatefulWidget {
  const GreetingHistory({super.key});

  @override
  State<GreetingHistory> createState() => _GreetingHistoryState();
}

class _GreetingHistoryState extends State<GreetingHistory> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> greetings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGreetingHistory();
  }

  Future<void> fetchGreetingHistory() async {
    final response = await supabase
        .from('greetings_sent')
        .select('id, greeting_type, message, sent_on, delivery_status, client_master(first_name, last_name)')
        .order('sent_on', ascending: false);

    setState(() {
      greetings = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  String formatClientName(Map client) {
    final fname = client['first_name'] ?? '';
    final lname = client['last_name'] ?? '';
    return '$fname $lname'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Greeting History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchGreetingHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: greetings.length,
          itemBuilder: (_, index) {
            final item = greetings[index];
            final client = item['client_master'] ?? {};
            final name = formatClientName(client);
            final date = DateFormat.yMMMd().format(DateTime.parse(item['sent_on']));
            final type = item['greeting_type'];
            final status = item['delivery_status'];

            return Card(
              child: ListTile(
                leading: Icon(_getGreetingIcon(type)),
                title: Text('$type - $name'),
                subtitle: Text('${item['message'] ?? ''}\nSent on $date'),
                trailing: Text(status),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getGreetingIcon(String type) {
    switch (type) {
      case 'Birthday':
        return Icons.cake;
      case 'Anniversary':
        return Icons.favorite;
      case 'Festival':
        return Icons.celebration;
      default:
        return Icons.card_giftcard;
    }
  }
}