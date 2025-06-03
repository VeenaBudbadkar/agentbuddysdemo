import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final result = await supabase.from('client_master').select();

      // Check each client if they have a purchase and update status
      for (var client in result) {
        final clientId = client['id'];
        final purchase = await supabase
            .from('policy_master')
            .select()
            .eq('client_id', clientId)
            .maybeSingle();

        if (purchase != null && client['status'] != 'Client') {
          await supabase.from('client_master').update({'status': 'Client'}).eq('id', clientId);
          client['status'] = 'Client';
        }
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
                Expanded(child: Text('Group Head', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Members', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(client['family_code'] ?? '-')),
                        Expanded(child: Text('${client['first_name']} ${client['last_name']}')),
                        Expanded(child: Text('${client['total_family_members'] ?? '1'}')),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (client['status'] == 'Client')
                                  ? Colors.lightGreen.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(client['status'] ?? 'Service'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add New Client',
        child: const Icon(Icons.add),
      ),
    );
  }
}
