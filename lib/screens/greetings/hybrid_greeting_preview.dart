import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'greeting_template_preview_screen.dart';

class HybridGreetingPage extends StatefulWidget {
  const HybridGreetingPage({super.key});

  @override
  State<HybridGreetingPage> createState() => _HybridGreetingPageState();
}

class _HybridGreetingPageState extends State<HybridGreetingPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tabController;
  final List<String> tabs = ['🎂 Birthdays', '💍 Anniversaries', '🎉 Festivals', '✨ Special Days'];

  final Map<String, List<Map<String, dynamic>>> templatesPerTab = {
    '🎂 Birthdays': [],
    '💍 Anniversaries': [],
    '🎉 Festivals': [],
    '✨ Special Days': [],
  };

  List<Map<String, dynamic>> allLeads = [];
  List<Map<String, dynamic>> filteredLeads = [];
  List<Map<String, dynamic>> selectedLeads = [];

  String searchQuery = '';
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this)
      ..addListener(_handleTabChange);
    _fetchAllTemplates();
    _fetchAllLeads();
  }

  void _handleTabChange() {
    _filterLeads();
    setState(() {});
  }

  Future<void> _fetchAllTemplates() async {
    final response = await supabase.from('greeting_template_master').select();
    for (var template in response) {
      final cat = template['category'].toString().toLowerCase();
      if (cat.contains('birthday')) templatesPerTab['🎂 Birthdays']!.add(template);
      else if (cat.contains('anniversary')) templatesPerTab['💍 Anniversaries']!.add(template);
      else if (cat.contains('festival')) templatesPerTab['🎉 Festivals']!.add(template);
      else templatesPerTab['✨ Special Days']!.add(template);
    }
    setState(() {});
  }

  Future<void> _fetchAllLeads() async {
    final response = await supabase.from('lead_master').select();
    allLeads = List<Map<String, dynamic>>.from(response);
    _filterLeads();
  }

  void _filterLeads() {
    final tab = tabs[_tabController.index];
    final today = DateTime.now();
    if (tab == '🎂 Birthdays') {
      filteredLeads = allLeads.where((lead) {
        final dob = DateTime.tryParse(lead['dob'] ?? '');
        return dob != null && dob.month == today.month;
      }).toList();
    } else if (tab == '💍 Anniversaries') {
      filteredLeads = allLeads.where((lead) {
        final ann = DateTime.tryParse(lead['anniversary_date'] ?? '');
        return ann != null && ann.month == today.month;
      }).toList();
    } else if (tab == '🎉 Festivals') {
      filteredLeads = allLeads; // your festival filter logic here
    } else {
      filteredLeads = [...allLeads];
    }

    if (searchQuery.isNotEmpty) {
      filteredLeads = filteredLeads.where((lead) {
        final name = lead['name']?.toLowerCase() ?? '';
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectAll) {
      selectedLeads = [...filteredLeads];
    } else {
      selectedLeads.removeWhere((lead) => !filteredLeads.contains(lead));
    }

    setState(() {});
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      selectAll = value;
      if (value) {
        selectedLeads = [...filteredLeads];
      } else {
        selectedLeads.clear();
      }
    });
  }

  void _toggleLead(Map<String, dynamic> lead) {
    setState(() {
      if (selectedLeads.contains(lead)) {
        selectedLeads.remove(lead);
      } else {
        selectedLeads.add(lead);
      }
    });
  }

  int calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    final birthDate = DateTime.tryParse(dob);
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String number) async {
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number found!')),
      );
      return;
    }
    final formatted = number.startsWith('+') ? number : '+91$number';
    final uri = Uri.parse('https://wa.me/${formatted.replaceAll('+', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  void _handleTemplateTap(Map<String, dynamic> template) {
    if (selectedLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one contact')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GreetingTemplatePreviewScreen(
          template: template,
          clientName: selectedLeads[0]['name'],
          agentName: 'Agent Name',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = templatesPerTab[tabs[_tabController.index]] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🎉 Greeting Hub'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return GestureDetector(
                  onTap: () => _handleTemplateTap(template),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            template['image_url'] ?? '',
                            height: 120,
                            width: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(template['template_name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                      suffixIcon: const Text('🎉', style: TextStyle(fontSize: 20)),
                      hintText: 'Search contacts...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      _filterLeads();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Select All', style: TextStyle(color: Colors.deepPurple)),
                    Checkbox(
                      value: selectAll,
                      onChanged: (v) => _toggleSelectAll(v!),
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                final age = calculateAge(lead['dob']);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: selectedLeads.contains(lead),
                      onChanged: (v) => _toggleLead(lead),
                      activeColor: Colors.deepPurple,
                    ),
                    title: Text('${lead['name']} (${age} yrs)'),
                    subtitle: Text('Status: ${lead['category'] ?? 'N/A'}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _call(lead['phone'] ?? ''),
                        ),
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.blue),
                          onPressed: () => _email(lead['email'] ?? ''),
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.teal),
                          onPressed: () => _whatsapp(lead['phone'] ?? ''),
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
    );
  }
}
