// ✅ Part: Trigger Carousel with Supabase Counts + Left-Aligned Badge Inside Button
import 'package:flutter/material.dart';
import 'package:agentbuddys/screens/clients/filtered_client_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TriggerCarousel extends StatefulWidget {
  const TriggerCarousel({super.key});

  @override
  State<TriggerCarousel> createState() => _TriggerCarouselState();
}

class _TriggerCarouselState extends State<TriggerCarousel> {
  final supabase = Supabase.instance.client;
  final List<Map<String, String>> triggerButtons = [
    {"label": "🎯 First Policy", "key": "first_policy"},
    {"label": "👶 Kids < 7", "key": "children_under_7"},
    {"label": "💍 Married", "key": "married"},
    {"label": "🎂 Age Milestone", "key": "age_milestone"},
    {"label": "🎁 New Milestone", "key": "life_event"},
    {"label": "🔒 Seasonal Traders", "key": "seasonal_traders"},
  ];

  Map<String, int> triggerCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTriggerCounts();
  }

  void _loadTriggerCounts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final conditions = {
      'first_policy': ['policy_count', 0],
      'children_under_7': ['age', 7],
      'married': ['marital_status', 'Married'],
      'age_milestone': ['age', 50],
      'life_event': ['life_event', true],
      'seasonal_traders': ['seasonal_trader', true],
    };

    Map<String, int> counts = {};

    for (var entry in conditions.entries) {
      final response = await supabase
          .from('client_master')
          .select('id', const FetchOptions(head: true, count: CountOption.exact))
          .eq('agent_id', user.id)
          .eq(entry.value[0] as String, entry.value[1]);

      counts[entry.key] = response.count ?? 0;
    }


    setState(() => triggerCounts = counts);
  }

  void _fetchFilteredClients(String triggerKey) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String queryField = '';
    dynamic queryValue;

    switch (triggerKey) {
      case 'first_policy':
        queryField = 'policy_count';
        queryValue = 0;
        break;
      case 'children_under_7':
        queryField = 'age';
        queryValue = 7;
        break;
      case 'married':
        queryField = 'marital_status';
        queryValue = 'Married';
        break;
      case 'age_milestone':
        queryField = 'age';
        queryValue = 50;
        break;
      case 'life_event':
        queryField = 'life_event';
        queryValue = true;
        break;
      case 'seasonal_traders':
        queryField = 'seasonal_trader';
        queryValue = true;
        break;
    }

    final response = await supabase
        .from('client_master')
        .select()
        .eq('agent_id', user.id)
        .eq(queryField, queryValue);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FilteredClientListScreen(
            triggerKey: triggerKey,
            filteredClients: response,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                "🚀 Hot Business Triggers",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: triggerButtons.length,
                itemBuilder: (context, index) {
                  final button = triggerButtons[index];
                  final count = triggerCounts[button['key']] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ActionChip(
                      shape: StadiumBorder(
                        side: BorderSide(color: Colors.deepPurple.shade100),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 3,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black87, width: 1),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            button['label']!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      onPressed: () => _fetchFilteredClients(button['key']!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
