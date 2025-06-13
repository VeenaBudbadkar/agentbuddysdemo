// ✅ PART 2: Supporting Widgets – Filtered List + Rank Card + Navigation
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔹 FilteredClientListScreen (Live Supabase Query Version)
class FilteredClientListScreen extends StatefulWidget {
  final String triggerKey;

  const FilteredClientListScreen({super.key, required this.triggerKey});

  @override
  State<FilteredClientListScreen> createState() => _FilteredClientListScreenState();
}

class _FilteredClientListScreenState extends State<FilteredClientListScreen> {
  List<dynamic> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchClientsByTrigger();
  }

  Future<void> fetchClientsByTrigger() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) return;

    final clientTable = Supabase.instance.client.from('client_master');
    final trigger = widget.triggerKey;
    dynamic data;

    if (trigger == "first_policy") {
      data = await clientTable.select().eq('agent_id', agentId).eq('policy_count', 0);
    } else if (trigger == "children_under_7") {
      data = await clientTable.select().eq('agent_id', agentId).lte('child_age', 7);
    } else if (trigger == "married") {
      data = await clientTable.select().eq('agent_id', agentId).eq('marital_status', 'Married');
    } else if (trigger == "age_milestone") {
      data = await clientTable.select().eq('agent_id', agentId).in_('age', [25, 30, 40, 50]);
    } else if (trigger == "life_event") {
      data = await clientTable.select().eq('agent_id', agentId).ilike('life_events', '%new%');
    } else if (trigger == "nomination_check") {
      data = await clientTable.select().eq('agent_id', agentId).is_('nominee_name', null);
    } else if (trigger == "ask_reference") {
      data = await clientTable.select().eq('agent_id', agentId).eq('can_give_reference', true);
    } else {
      data = await clientTable.select().eq('agent_id', agentId);
    }

    setState(() {
      _clients = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Clients: ${widget.triggerKey}")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text("${client['first_name']} ${client['last_name'] ?? ''}"),
            subtitle: Text("Age: ${client['age']}"),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // Add WhatsApp/message action here
              },
            ),
          );
        },
      ),
    );
  }
}

// 🔹 RankCard Widget (For Future Use in Leaderboard Section)
class RankCardWidget extends StatelessWidget {
  final String emoji;
  final String name;
  final String branch;
  final String company;
  final String location;
  final String metric;
  final String value;

  const RankCardWidget({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("($branch) $company, $location", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Text("$metric: $value", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}