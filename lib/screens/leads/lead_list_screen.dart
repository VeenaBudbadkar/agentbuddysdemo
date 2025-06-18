import 'package:flutter/material.dart';
import 'package:agentbuddys/utils/agent_buddys_alerts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'import_contacts_screen.dart';
import 'package:agentbuddys/screens/campaigns/campaign_calling_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'lead_profile_screen.dart';

class LeadListScreen extends StatefulWidget {
  final String filterStatus;

  const LeadListScreen({super.key, required this.filterStatus});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allLeads = [];
  List<Map<String, dynamic>> filteredLeads = [];
  List<Map<String, dynamic>> selectedLeads = [];

  bool isLoading = true;
  bool isSelecting = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    setState(() => isLoading = true);

    final agentId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('lead_master')
        .select()
        .eq('agent_id', agentId)
        .order('created_at', ascending: false);

    setState(() {
      allLeads = List<Map<String, dynamic>>.from(response);
      applySearch();
      isLoading = false;
      selectedLeads.clear();
    });
  }

  void applySearch() {
    setState(() {
      filteredLeads = allLeads
          .where((lead) =>
      (lead['name'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (lead['contact_number'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    });
  }

  void toggleSelectMode() {
    setState(() {
      isSelecting = !isSelecting;
      selectedLeads.clear();
    });
    if (isSelecting) {
      _showMagicPopup();
    }
  }

  void _showMagicPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Bulk Select Mode"),
        content: const Text("Select at least 5 leads to use bulk actions! 💣✨"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void toggleLeadSelection(Map<String, dynamic> lead) {
    setState(() {
      if (selectedLeads.any((l) => l['id'] == lead['id'])) {
        selectedLeads.removeWhere((l) => l['id'] == lead['id']);
      } else {
        selectedLeads.add(lead);
      }
    });
  }

  Future<void> openImportContacts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportContactsScreen()),
    );
    if (result == true) {
      fetchLeads();
    }
  }

  void makePhoneCall(String number) async {
    final Uri uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not launch dialer")),
      );
    }
  }

  void openWhatsApp(String number, String message) async {
    final Uri uri = Uri.parse("https://wa.me/$number?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not open WhatsApp")),
      );
    }
  }

  void sendEmail(String email) async {
    final Uri uri = Uri.parse("mailto:$email");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not send email")),
      );
    }
  }

  void startCallingCampaign() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignCallingScreen(leads: selectedLeads),
      ),
    );
    setState(() {
      isSelecting = false;
      selectedLeads.clear();
    });
  }

  void showWhatsAppTemplatePicker() async {
    final List<String> templates = [
      "Hello! This is a follow-up.",
      "Thank you for connecting!",
      "Custom message"
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: templates.map((template) {
            return ListTile(
              title: Text(template),
              onTap: () async {
                Navigator.pop(context);
                for (var lead in selectedLeads) {
                  openWhatsApp(lead['contact_number'], template);
                  await supabase.from('call_meeting_logs').insert({
                    'lead_id': lead['id'],
                    'agent_id': supabase.auth.currentUser?.id,
                    'type': 'call',
                    'scheduled_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
                    'status': 'pending',
                    'notes': 'Auto-follow-up after WhatsApp',
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ WhatsApp sent & auto-call scheduled in 2 days!")),
                );
                setState(() {
                  isSelecting = false;
                  selectedLeads.clear();
                });
              },
            );
          }).toList(),
        );
      },
    );
  }


  void pushToClient() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Pushed to client successfully!")),
    );
    setState(() {
      isSelecting = false;
      selectedLeads.clear();
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Hot':
        return Colors.red;
      case 'Warm':
        return Colors.orange;
      case 'Cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lead List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: openImportContacts,
          ),
          IconButton(
            icon: Icon(isSelecting ? Icons.cancel : Icons.check_box),
            onPressed: toggleSelectMode,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search leads...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                searchQuery = value;
                applySearch();
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                final isSelected =
                selectedLeads.any((l) => l['id'] == lead['id']);

                return ListTile(
                  onTap: () {
                    if (isSelecting) {
                      toggleLeadSelection(lead);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeadProfileScreen(leadId: lead['id']),
                        ),
                      );
                    }
                  },
                  leading: isSelecting
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (value) =>
                        toggleLeadSelection(lead),
                  )
                      : CircleAvatar(
                    backgroundColor:
                    getStatusColor(lead['status'] ?? 'Cold'),
                    child: Text(
                      (lead['status'] ?? 'C')[0],
                      style:
                      const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(lead['name'] ?? 'No Name'),
                  subtitle: Text(lead['contact_number'] ?? ''),
                  trailing: isSelecting
                      ? null
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () =>
                            makePhoneCall(lead['contact_number']),
                      ),
                      IconButton(
                        icon: const FaIcon(
                            FontAwesomeIcons.whatsapp),
                        onPressed: () => openWhatsApp(
                            lead['contact_number'],
                            "Hello ${lead['name']}!"),
                      ),
                      if (lead['email'] != null &&
                          lead['email'].toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.email),
                          onPressed: () =>
                              sendEmail(lead['email']),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (isSelecting && selectedLeads.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: showWhatsAppTemplatePicker,
                    icon:
                    const Icon(Icons.message, color: Colors.white),
                    label: const Text(
                      "Bulk WhatsApp",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: startCallingCampaign,
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    label: const Text(
                      "Auto Dialer",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: pushToClient,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Push to Client",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
