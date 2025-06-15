import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agentbuddys/services/auto_dialer/auto_dialer_engine.dart';

class CampaignListScreen extends StatefulWidget {
  final String? preSelectedStage;
  final String? preSelectedCategory;
  final bool? hotTriggerOnly;

  const CampaignListScreen({
    super.key,
    this.preSelectedStage,
    this.preSelectedCategory,
    this.hotTriggerOnly,
  });

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;

  String selectedStage = 'Lead';
  String selectedCategory = 'All';
  bool hotTriggerOnly = false;

  List<Map<String, dynamic>> filteredContacts = [];
  List<Map<String, dynamic>> selectedContacts = [];

  final List<String> stages = ['Lead', 'Client'];
  final List<String> categories = ['All', 'Doctor', 'Children', 'Retired', 'Business'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedStage = widget.preSelectedStage ?? 'Lead';
    selectedCategory = widget.preSelectedCategory ?? 'All';
    hotTriggerOnly = widget.hotTriggerOnly ?? false;
    _fetchContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    String table = selectedStage == 'Lead' ? 'lead_master' : 'client_master';
    var query = supabase.from(table)
        .select('id, name, contact_number, is_dialed, tag, hot_trigger')
        .eq('is_dialed', false);

    if (selectedCategory != 'All') query = query.eq('tag', selectedCategory);
    if (hotTriggerOnly) query = query.eq('hot_trigger', true);

    final response = await query;
    setState(() {
      filteredContacts = List<Map<String, dynamic>>.from(response);
      selectedContacts.clear();
    });
  }

  Future<void> _startCampaignDialer() async {
    if (selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select contacts first!")),
      );
      return;
    }
    final dialer = AutoDialerEngine(
      context: context,
      contacts: selectedContacts,
      campaignName: "${selectedStage}_${selectedCategory}_Campaign",
      triggerFilters: [
        selectedStage,
        selectedCategory,
        if (hotTriggerOnly) "Hot Trigger",
      ],
      selectedStage: selectedStage,
    );
    dialer.start();
  }

  Future<void> _resetDialStatusFilteredBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Confirm Reset"),
        content: Text("Reset dial status for ${filteredContacts.length} filtered contacts?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Yes, Reset")),
        ],
      ),
    );

    if (confirm != true) return;

    final table = selectedStage == 'Lead' ? 'lead_master' : 'client_master';
    final ids = filteredContacts.map((c) => c['id']).toList();
    if (ids.isEmpty) return;

    await supabase.from(table).update({'is_dialed': false}).in_('id', ids);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Reset ${ids.length} filtered contacts.")),
    );
    _fetchContacts();
  }

  Future<void> _resetCampaignLogs() async {
    await supabase.from('campaign_call_logs').delete().neq('id', 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ All campaign logs cleared!")),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedStage,
              items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                setState(() => selectedStage = v!);
                _fetchContacts();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selectedCategory,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                setState(() => selectedCategory = v!);
                _fetchContacts();
              },
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              const Text("Hot Trigger"),
              Checkbox(
                value: hotTriggerOnly,
                onChanged: (v) {
                  setState(() => hotTriggerOnly = v!);
                  _fetchContacts();
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📞 Campaign Dialer")),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: filteredContacts.isEmpty
                ? const Center(child: Text("No contacts found."))
                : ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (_, i) {
                final c = filteredContacts[i];
                final selected = selectedContacts.any((x) => x['id'] == c['id']);
                return ListTile(
                  leading: Checkbox(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          if (!selectedContacts.any((x) => x['id'] == c['id'])) {
                            selectedContacts.add(c);
                          }
                        } else {
                          selectedContacts.removeWhere((x) => x['id'] == c['id']);
                        }
                      });
                    },
                  ),
                  title: Text(c['name'] ?? ''),
                  subtitle: Text(c['contact_number'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () => launchCaller(c['contact_number']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Campaign Dialer"),
                  onPressed: _startCampaignDialer,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset Filtered Dial Status"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: _resetDialStatusFilteredBatch,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Reset All Campaign Logs"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                  onPressed: _resetCampaignLogs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Universal helper
void launchCaller(String phoneNumber) async {
  final url = 'tel:$phoneNumber';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}
