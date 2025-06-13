import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/contact_utils.dart'; // Make sure this exists
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CallListScreen extends StatefulWidget {
  const CallListScreen({super.key});

  @override
  State<CallListScreen> createState() => _CallListScreenState();
}

class _CallListScreenState extends State<CallListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> callLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchCallLogs();
  }

  Future<void> _fetchCallLogs() async {
    final response = await supabase
        .from('call_meeting_logs')
        .select('*, lead_master(name, contact_number, email)')
        .eq('type', 'Call');
    setState(() {
      callLogs = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> updateKPI(String agentId, String metricType) async {
    final now = DateTime.now();
    final monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    await supabase.rpc('update_kpi_metric', params: {
      'agent_id_input': agentId,
      'month_year_input': monthYear,
      'metric_type': metricType,
    });
  }

  void _showCallDialog({Map<String, dynamic>? log}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? subAction = log?['sub_type'];
        List<String> subActionOptions = [
          '1st Appointment',
          'Follow-up: Decision',
          'Follow-up: Document',
          'Follow-up: Premium',
          'Servicing Call',
          'Relationship Call',
          'Custom'
        ];
        DateTime selectedDate = DateTime.now();
        TextEditingController notesController =
        TextEditingController(text: log?['notes'] ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Call Feedback"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Sub Action'),
                      value: subAction,
                      items: subActionOptions
                          .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => subAction = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Next Follow-up Date:"),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Pick a Date"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await supabase.from('call_meeting_logs').insert({
                      'agent_id': log?['agent_id'],
                      'lead_id': log?['lead_id'],
                      'type': 'Call',
                      'sub_type': subAction,
                      'notes': notesController.text,
                      'followup_date': selectedDate.toIso8601String(),
                      'created_at': DateTime.now().toIso8601String(),
                    });

                    await updateKPI(log?['agent_id'], subAction == '1st Appointment' ? 'first_calls' : 'followups');

                    Navigator.of(context).pop();
                    _fetchCallLogs();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getRowColor(String? purpose) {
    if (purpose == null) return Colors.white;
    if (purpose.contains("Premium") || purpose.contains("Document")) {
      return Colors.green.shade100;
    } else if (purpose.contains("Servicing")) {
      return Colors.orange.shade100;
    } else {
      return Colors.yellow.shade100;
    }
  }

  Widget _buildCallItem(Map<String, dynamic> log) {
    final lead = log['lead_master'] ?? {};
    final leadName = lead['name'] ?? 'Unknown';
    final contact = lead['contact_number'] ?? '';
    final email = lead['email'] ?? '';

    return GestureDetector(
      onTap: () {},
      child: Card(
        color: _getRowColor(log['sub_type']),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leadName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(log['sub_type'] ?? '', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showCallDialog(log: log),
                child: Text("Note: ${log['notes'] ?? ''}",
                    style: const TextStyle(color: Colors.blue)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () => launchCaller(contact),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.teal),
                    onPressed: () => launchWhatsApp(contact),
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, color: Colors.deepPurple),
                    onPressed: () => launchEmail(email),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.blue),
                    onPressed: () => _showCallDialog(log: log),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call List")),
      body: ListView(
        children: callLogs.map(_buildCallItem).toList(),
      ),
    );
  }
}
