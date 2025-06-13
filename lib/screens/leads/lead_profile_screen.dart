import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agentbuddys/screens/clients/client_master_form.dart';


class LeadProfileScreen extends StatefulWidget {
  final String leadId;

  const LeadProfileScreen({super.key, required this.leadId});

  @override
  State<LeadProfileScreen> createState() => _LeadProfileScreenState();
}

class _LeadProfileScreenState extends State<LeadProfileScreen> {
  String? selectedLogType; // 'Call' or 'Meeting'
  String? selectedInteractionLevel; // '1st Appointment' or 'Follow-up'
  String? selectedFollowupReason; // Reason inside Follow-up
  TextEditingController customFollowupReasonController = TextEditingController(); // If custom reason typed

  DateTime? followUpDate;
  final supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Map<String, dynamic>? lead;
  bool loading = true;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController customActionController = TextEditingController();
  final TextEditingController customGoalController = TextEditingController();
  String? selectedNextAction;

  bool showAllNotes = false;
  Map<String, List<Map<String, dynamic>>> groupedNotes = {};
  final ScrollController _noteScrollController = ScrollController();

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return Colors.red;
      case 'warm':
        return Colors.orange;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeadData();
    initializeNotifications();
  }

  void initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('default_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification(String dateString) async {
    final dateTime = DateTime.tryParse(dateString);
    if (dateTime == null || dateTime.isBefore(DateTime.now())) return;
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'follow_up_channel',
      'Follow Up Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Follow-up Reminder',
      'You have a follow-up scheduled today.',
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> fetchLeadData() async {
    try {
      final result = await supabase.from('lead_master').select().eq('id', widget.leadId).single();
      setState(() {
        lead = result;
        loading = false;
        selectedNextAction = result['next_action'];
      });

      final allNotes = lead?['notes'] is List ? List<Map<String, dynamic>>.from(lead!['notes']) : [];
      groupedNotes = {};

      for (var note in allNotes) {
        final dateStr = note['date'] ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final monthYear = DateFormat('MMMM yyyy').format(date);
        if (!groupedNotes.containsKey(monthYear)) {
          groupedNotes[monthYear] = [];
        }
        groupedNotes[monthYear]!.add(note);
      }

      if (lead?['followup_date'] != null) {
        scheduleNotification(lead!['followup_date']);
      }
    } catch (e) {
      print('Error fetching lead: $e');
    }
  }

  void shareNotes() {
    final buffer = StringBuffer();
    groupedNotes.forEach((month, notes) {
      buffer.writeln('--- $month ---');
      for (var note in notes) {
        final date = _formatDateTime(note['date'] ?? '');
        final text = note['note'] ?? '';
        buffer.writeln('$date\n$text\n');
      }
    });
    Share.share(buffer.toString(), subject: 'Client Notes History');
  }

  void addNote() {
    if (lead == null || noteController.text.trim().isEmpty) return;
    final now = DateTime.now();
    final newNote = {
      'date': now.toIso8601String(),
      'note': noteController.text.trim()
    };
    final monthYear = DateFormat('MMMM yyyy').format(now);

    setState(() {
      if (!groupedNotes.containsKey(monthYear)) {
        groupedNotes[monthYear] = [];
      }
      groupedNotes[monthYear]!.insert(0, newNote);
      noteController.clear();
      _noteScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatDateTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return 'Invalid date';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  void _launchPhone(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchWhatsApp(String number) async {
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nextActionOptions = [
      'Call', 'Call Back', 'Send Proposal', 'Follow Up', 'Fix Appointment',
      'Send Greetings', 'Collect Documents', 'Custom Action'
    ];
    final financialGoals = [
      'Retirement', 'Children Education', 'Marriage', 'Mediclaim',
      'Life Cover', 'Tax Saving', 'Wealth Creation', 'Custom Goal'
    ];
    final productInterests = [
      'Term Plan', 'Money Back', 'Endowment', 'ULIP', 'Pension', 'Mediclaim'
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: getStatusColor(lead?['status'] ?? ''),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(lead?['name'] ?? 'Lead')),
            PopupMenuButton<String>(
              initialValue: lead?['status'],
              onSelected: (value) => setState(() => lead!['status'] = value),
              itemBuilder: (context) => ['Hot', 'Warm', 'Cold'].map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: getStatusColor(status), size: 12),
                      const SizedBox(width: 8),
                      Text(status)
                    ],
                  ),
                );
              }).toList(),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: getStatusColor(lead?['status'] ?? '')),
                  const SizedBox(width: 6),
                  Text(lead?['status'] ?? '', style: const TextStyle(color: Colors.white)),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: shareNotes),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Contact Number'),
                    subtitle: Text(lead?['contact_number'] ?? '—'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                          onPressed: () => _launchWhatsApp(lead?['contact_number'] ?? ''),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.blue),
                          onPressed: () => _launchPhone(lead?['contact_number'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Email'),
                    subtitle: Text(lead?['email'] ?? '—'),
                    trailing: IconButton(
                      icon: const Icon(Icons.email, color: Colors.orange),
                      onPressed: () => _launchEmail(lead?['email'] ?? ''),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("🎯 Financial Goal"),
                  DropdownButtonFormField<String>(
                    value: lead?['financial_goal'],
                    items: financialGoals.map((goal) => DropdownMenuItem(
                      value: goal,
                      child: Text(goal),
                    )).toList(),
                    onChanged: (value) {
                      if (value == 'Custom Goal') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Enter Custom Goal"),
                            content: TextField(controller: customGoalController),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  setState(() => lead!['financial_goal'] = customGoalController.text);
                                  Navigator.pop(context);
                                },
                                child: const Text("Save"),
                              )
                            ],
                          ),
                        );
                      } else {
                        setState(() => lead!['financial_goal'] = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("📦 Product Interest"),
                  DropdownButtonFormField<String>(
                    value: lead?['product_interest'],
                    items: productInterests.map((product) => DropdownMenuItem(
                      value: product,
                      child: Text(product),
                    )).toList(),
                    onChanged: (value) => setState(() => lead!['product_interest'] = value),
                  ),
                  const Text("📝 Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: ListView(
                      controller: _noteScrollController,
                      children: groupedNotes.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            ...entry.value.map((note) {
                              final noteText = note['note'] ?? '';
                              final noteDate = note['date'] ?? '';
                              final isDeletable = DateTime.now().difference(DateTime.parse(noteDate)).inHours < 24;
                              return Card(
                                child: ListTile(
                                  title: Text(noteText),
                                  subtitle: Text(_formatDateTime(noteDate)),
                                  trailing: isDeletable
                                      ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        entry.value.remove(note);
                                      });
                                    },
                                  )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Add Note',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: addNote,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("🧭 Next Action", style: TextStyle(fontWeight: FontWeight.bold)),

                  DropdownButtonFormField<String>(
                    value: selectedLogType,
                    hint: const Text("Select Action Type"),
                    items: ['Call', 'Meeting'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLogType = value;
                        selectedInteractionLevel = null;
                        selectedFollowupReason = null;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  if (selectedLogType != null)
                    DropdownButtonFormField<String>(
                      value: selectedInteractionLevel,
                      hint: const Text("Select Appointment Type"),
                      items: ['1st Appointment', 'Follow-up'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedInteractionLevel = value;
                          selectedFollowupReason = null;
                        });
                      },
                    ),

                  const SizedBox(height: 16),

                  if (selectedInteractionLevel == 'Follow-up')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedFollowupReason,
                          hint: const Text("Select Follow-up Reason"),
                          items: [
                            'Servicing',
                            'Document Collection',
                            'Decision Pending',
                            'Custom Reason'
                          ].map((reason) {
                            return DropdownMenuItem(value: reason, child: Text(reason));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFollowupReason = value;
                            });
                          },
                        ),
                        if (selectedFollowupReason == 'Custom Reason')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextFormField(
                              controller: customFollowupReasonController,
                              decoration: const InputDecoration(labelText: "Enter custom reason"),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedLogType == null || selectedInteractionLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please complete all Next Action fields.")),
                        );
                        return;
                      }

                      final logData = {
                        'agent_id': Supabase.instance.client.auth.currentUser?.id,
                        'lead_id': lead!['id'], // Make sure `lead` is defined in your screen
                        'log_type': selectedLogType,
                        'interaction_level': selectedInteractionLevel,
                        'followup_reason': selectedInteractionLevel == 'Follow-up'
                            ? (selectedFollowupReason == 'Custom Reason'
                            ? customFollowupReasonController.text
                            : selectedFollowupReason)
                            : null,
                        'created_at': DateTime.now().toIso8601String(),
                      };

                      final response = await Supabase.instance.client
                          .from('call_meeting_logs')
                          .insert(logData);

                      if (response != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Next Action saved successfully!")),
                        );
                        setState(() {
                          selectedLogType = null;
                          selectedInteractionLevel = null;
                          selectedFollowupReason = null;
                          customFollowupReasonController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error saving Next Action")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Save Action"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),

                  const SizedBox(height: 20),
                  const Text("📅 Follow-up Date"),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: followUpDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          followUpDate = pickedDate;
                          lead!['followup_date'] = pickedDate.toIso8601String();
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Pick a date',
                      ),
                      child: Text(
                        followUpDate != null
                            ? DateFormat('dd MMM yyyy').format(followUpDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person_add_alt_1),
                    label: Text("Convert to Client"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientMasterForm(
                            prefilledLead: {
                              'first_name': lead?['first_name'],
                              'last_name': lead?['last_name'],
                              'mobile': lead?['contact_number'],
                              'email': lead?['email'],
                              'lead_id': lead?['id'],
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Lead to Client'),
        onPressed: () {
          if (lead != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientMasterForm(
                  prefilledLead: {
                    'first_name': lead?['first_name'],
                    'last_name': lead?['last_name'],
                    'mobile': lead?['contact_number'],
                    'email': lead?['email'],
                    'lead_id': lead?['id'],
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❗ No lead data available')),
            );
          }
        },
      ),
    );
  }
}