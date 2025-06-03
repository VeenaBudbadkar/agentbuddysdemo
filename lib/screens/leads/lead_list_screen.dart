import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lead_profile_screen.dart'; // ✅ Make sure this path is correct

class LeadListScreen extends StatefulWidget {
  const LeadListScreen({super.key});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> leads = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    print('🟡 Fetching leads from Supabase...');
    try {
      final response = await supabase
          .from('lead_master')
          .select('id, name, status, product_interest, state, city')
          .order('created_at', ascending: false);

      print('✅ Leads loaded: ${response.length}'); // <-- log how many

      setState(() {
        leads = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      print('🔥 Supabase fetch failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leads: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loading) {
      print('📊 Total leads loaded: ${leads.length}');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lead List')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          final name = lead['name'] ?? 'Unnamed';
          final interest = lead['product_interest'] ?? 'No interest';
          final status = (lead['status'] ?? 'cold').toLowerCase();

          Color statusColor;
          switch (status) {
            case 'hot':
              statusColor = Colors.red;
              break;
            case 'warm':
              statusColor = Colors.orange;
              break;
            default:
              statusColor = Colors.blue;
          }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadProfileScreen(leadId: lead['id']),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.blue.withOpacity(0.2),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status color dot
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Lead name + interest + location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(interest,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          _formatLocation(lead['state'], lead['city']),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Action icons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, size: 20),
                        onPressed: () {
                          // TODO: Call action
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, size: 20),
                        onPressed: () {
                          // TODO: WhatsApp action
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.email, size: 20),
                        onPressed: () {
                          // TODO: Email action
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
String _formatLocation(String? state, String? city) {
  if (state == null || city == null || state.isEmpty || city.isEmpty) {
    return 'Unknown Location';
  }
  String stateCode = state.length >= 3
      ? state.substring(0, 3).toUpperCase()
      : state.toUpperCase();
  return '$stateCode/$city';
}
