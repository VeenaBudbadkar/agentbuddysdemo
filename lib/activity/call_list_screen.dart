import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // ✅ Ensures WidgetsBindingObserver works
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/contact_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CallListScreen extends StatefulWidget {
  const CallListScreen({super.key});

  @override
  State<CallListScreen> createState() => _CallListScreenState();
}

class _CallListScreenState extends State<CallListScreen> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> followUps = [];

  List<Map<String, dynamic>> _autoDialList = [];
  int _currentCallIndex = 0;
  bool _isAutoDialerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchCallLogs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isAutoDialerActive) {
      Navigator.pop(context, true); // ensures update if auto dialer was active
    }
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAutoDialerActive && state == AppLifecycleState.resumed) {
      // Call ended, show feedback
      _showAutoFeedbackDialog(_autoDialList[_currentCallIndex]);
    }
  }

  Future<void> _fetchCallLogs() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final response = await supabase
        .from('call_meeting_logs')
        .select('*, lead_master(name, contact_number, email)')
        .eq('type', 'Call')
        .eq('next_action_date', today);

    List<Map<String, dynamic>> allCalls =
    List<Map<String, dynamic>>.from(response);

    setState(() {
      appointments = allCalls
          .where((log) => log['sub_type'] == '1st Appointment')
          .toList();
      followUps = allCalls
          .where((log) =>
      log['sub_type'] != '1st Appointment' && (log['sub_type'] ?? '') != '')
          .toList();
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

  Future<void> _startAutoDialer() async {
    _autoDialList = [...appointments, ...followUps];
    _currentCallIndex = 0;

    if (_autoDialList.isNotEmpty) {
      _isAutoDialerActive = true;
      _dialNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No calls to auto-dial!")),
      );
    }
  }

  Future<void> _dialNext() async {
    if (_currentCallIndex >= _autoDialList.length) {
      _isAutoDialerActive = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All calls completed!")),
      );
      Navigator.pop(context, true); // ✅ This returns TRUE to Dashboard!
      return;
    }

    final currentLog = _autoDialList[_currentCallIndex];
    final lead = currentLog['lead_master'] ?? {};
    final contact = lead['contact_number'] ?? '';

    launchCaller(contact);
    // We rely on `didChangeAppLifecycleState` to handle post-call
  }

  void _showAutoFeedbackDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      barrierDismissible: false, // Agent must submit feedback!
      builder: (BuildContext context) {
        String? subAction = log['sub_type'];
        DateTime selectedDate = DateTime.now();
        TextEditingController notesController =
        TextEditingController(text: log['notes'] ?? '');

        List<String> subActionOptions = [
          '1st Appointment',
          'Follow-up: Decision',
          'Follow-up: Document',
          'Follow-up: Premium',
          'Servicing Call',
          'Relationship Call',
          'Custom'
        ];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Call Summary & Next Action"),
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
                ElevatedButton(
                  onPressed: () async {
                    await supabase.from('call_meeting_logs').insert({
                      'agent_id': log['agent_id'],
                      'lead_id': log['lead_id'],
                      'type': 'Call',
                      'sub_type': subAction,
                      'notes': notesController.text,
                      'followup_date': selectedDate.toIso8601String(),
                      'created_at': DateTime.now().toIso8601String(),
                    });

                    await updateKPI(log['agent_id'],
                        subAction == '1st Appointment' ? 'first_calls' : 'followups');

                    Navigator.of(context).pop();

                    _currentCallIndex++;
                    _dialNext();
                  },
                  child: const Text("Save & Next"),
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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leadName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(log['sub_type'] ?? '',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showAutoFeedbackDialog(log),
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
                    icon: const FaIcon(FontAwesomeIcons.whatsapp,
                        color: Colors.teal),
                    onPressed: () => launchWhatsApp(contact),
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, color: Colors.deepPurple),
                    onPressed: () => launchEmail(email),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.blue),
                    onPressed: () => _showAutoFeedbackDialog(log),
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
      appBar: AppBar(title: const Text("Today's Calls")),
      body: appointments.isEmpty && followUps.isEmpty
          ? const Center(child: Text('No Calls for Today!'))
          : ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Auto Dialer"),
              onPressed: _startAutoDialer,
            ),
          ),
          if (appointments.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "1st Appointments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ...appointments.map(_buildCallItem).toList(),
          if (followUps.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Follow-Ups",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ...followUps.map(_buildCallItem).toList(),
        ],
      ),
    );
  }
}

// ✅ Helper launcher function
void launchCaller(String phoneNumber) async {
  final url = 'tel:$phoneNumber';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}
