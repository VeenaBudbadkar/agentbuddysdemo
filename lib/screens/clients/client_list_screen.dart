import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../clients/family_portfolio_screen.dart';
import 'client_master_form.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> clients = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredClients = [];

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() => loading = true);
    try {
      final currentAgentId = supabase.auth.currentUser?.id;
      final result = await supabase.from('client_master').select();

      for (var client in result) {
        final clientId = client['id'];

        final policies = await supabase
            .from('policy_master')
            .select('id, agent_id')
            .eq('client_id', clientId);

        final agentPolicies = policies.where((p) => p['agent_id'] == currentAgentId).toList();
        final policyCount = policies.length;

        client['total_policies'] = policyCount;

        if (agentPolicies.isNotEmpty) {
          client['status'] = 'Client';
        } else {
          client['status'] = 'Service';
        }

        client['last_contacted'] = client['last_contacted'] ?? '2025-06-10';

        await supabase.from('client_master').update({
          'status': client['status'],
        }).eq('id', clientId);
      }

      setState(() {
        clients = result;
        filteredClients = result;
        loading = false;
      });
    } catch (e) {
      print('Error fetching clients: $e');
      setState(() => loading = false);
    }
  }

  void _filterClients(String query) {
    setState(() {
      filteredClients = clients.where((client) {
        final name = '${client['first_name']} ${client['last_name']}'.toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> importCSV() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final rows = const LineSplitter().convert(content);

      final headers = rows.first.split(',');
      final clientsToInsert = <Map<String, dynamic>>[];

      for (var i = 1; i < rows.length; i++) {
        final values = rows[i].split(',');
        final Map<String, dynamic> row = {};

        for (int j = 0; j < headers.length; j++) {
          row[headers[j].trim()] = values[j].trim();
        }

        final lastName = row['last_name']?.toLowerCase() ?? 'x';
        final timeSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
        row['family_code'] ??= '${lastName[0]}000$timeSuffix';

        clientsToInsert.add(row);
      }

      try {
        await supabase.from('client_master').insert(clientsToInsert);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Clients imported successfully!')),
        );
        fetchClients();
      } catch (e) {
        print('Insert error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error importing data')),
        );
      }
    }
  }

  void _showServiceMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("🧡 Just a Free Service!"),
        content: const Text("You're giving only free service 😅\nSell a policy to turn me GREEN! 💼💰"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  void _showClientMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("💚 Policy Sold!"),
        content: const Text("Great job! 🎉 Ask your happy client for a referral now! 👨‍👩‍👧‍👦🔁"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay!"),
          ),
        ],
      ),
    );
  }

  void _navigateToFamilyPortfolio(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyPortfolioSummaryPage(
          familyCode: client['family_code'], // ✅ This is the fix
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(child: Text('Client Groups')),
            CircleAvatar(
              backgroundColor: Colors.blue.shade700,
              child: Text(
                '${filteredClients.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: importCSV,
            tooltip: 'Import from CSV',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterClients,
              decoration: InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  radius: 16,
                  child: Text(
                    '${filteredClients.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Row(
              children: const [
                Expanded(child: Text('Gr. Code', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Text('Last Contact', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: filteredClients.isEmpty
                ? const Center(child: Text('No clients found.'))
                : ListView.builder(
              itemCount: filteredClients.length,
              itemBuilder: (context, index) {
                final client = filteredClients[index];
                final lastContactedStr = client['last_contacted'];
                final lastContactedDate = lastContactedStr != null ? DateTime.tryParse(lastContactedStr) : null;
                final daysSinceContact = lastContactedDate != null ? DateTime.now().difference(lastContactedDate).inDays : null;
                final isStale = daysSinceContact != null && daysSinceContact > 60;
                final statusColor = (client['status'] == 'Client') ? Colors.green : Colors.orange;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: InkWell(
                    onTap: () => _navigateToFamilyPortfolio(client),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(client['family_code'] ?? '-')),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${client['first_name']} ${client['last_name']}'),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lastContactedStr ?? '-',
                                  style: TextStyle(
                                    color: isStale ? Colors.red : Colors.black,
                                    fontWeight: isStale ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (client['status'] == 'Service') {
                                      _showServiceMessage();
                                    } else {
                                      _showClientMessage();
                                    }
                                  },
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientMasterForm()),
        ),
        tooltip: 'Add New Client',
        child: const Icon(Icons.add),
      ),
    );
  }
}
