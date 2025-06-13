import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/contact_utils.dart'; // For launching call, WhatsApp, and email
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> meetingLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchMeetingLogs();
  }

  Future<void> _fetchMeetingLogs() async {
    final response = await supabase
        .from('call_meeting_logs')
        .select('*, lead_master(name, contact_number, email)')
        .eq('type', 'Meeting');
    setState(() {
      meetingLogs = List<Map<String, dynamic>>.from(response);
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

  void _showMeetingDialog({Map<String, dynamic>? log}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? subAction = log?['sub_type'];
        List<String> subActionOptions = [
          '2nd Proposal Meeting',
          'Form & Document Collection',
          'Medical',
          'Premium Collection',
          'Servicing - Other',
          'Relationship Meeting',
          'Custom'
        ];
        DateTime selectedDate = DateTime.now();
        TextEditingController notesController =
        TextEditingController(text: log?['notes'] ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Meeting Feedback"),
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
                      'type': 'Meeting',
                      'sub_type': subAction,
                      'notes': notesController.text,
                      'followup_date': selectedDate.toIso8601String(),
                      'created_at': DateTime.now().toIso8601String(),
                    });

                    await updateKPI(log?['agent_id'], subAction == '2nd Proposal Meeting' ? 'first_meetings' : 'followups');

                    Navigator.of(context).pop();
                    _fetchMeetingLogs();
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
    if (purpose.contains("Document") || purpose.contains("Medical")) {
      return Colors.green.shade100;
    } else if (purpose.contains("Servicing")) {
      return Colors.orange.shade100;
    } else {
      return Colors.yellow.shade100;
    }
  }

  Widget _buildMeetingItem(Map<String, dynamic> log) {
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
                onTap: () => _showMeetingDialog(log: log),
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
                    onPressed: () => _showMeetingDialog(log: log),
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
      appBar: AppBar(title: const Text("Meeting List")),
      body: ListView(
        children: meetingLogs.map(_buildMeetingItem).toList(),
      ),
    );
  }
}
