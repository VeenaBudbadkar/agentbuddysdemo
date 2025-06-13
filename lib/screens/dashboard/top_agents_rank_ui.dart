// ✅ Top Agent Rank UI - Supabase Live Data with Period Dropdown
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopAgentsRankUi extends StatefulWidget {
  const TopAgentsRankUi({super.key});

  @override
  State<TopAgentsRankUi> createState() => _TopAgentsRankUiState();
}

class _TopAgentsRankUiState extends State<TopAgentsRankUi> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> topByPremium = [];
  List<Map<String, dynamic>> topByNOP = [];
  String selectedPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    fetchTopAgents();
  }

  Future<void> fetchTopAgents() async {
    final now = DateTime.now();
    final String month = now.toString().substring(0, 7); // e.g. "2025-06"
    final String year = now.year.toString();

    final periodFilter = selectedPeriod == 'Monthly'
        ? {'field': 'month', 'value': month}
        : {'field': 'year', 'value': year};

    final response = await supabase
        .from('agent_profile')
        .select('name, monthly_rank, nop, total_premium')
        .eq(periodFilter['field']!, periodFilter['value'])
        .order('total_premium', ascending: false)
        .limit(3);

    final responseNOP = await supabase
        .from('agent_profile')
        .select('name, monthly_rank, nop, total_premium')
        .eq(periodFilter['field']!, periodFilter['value'])
        .order('nop', ascending: false)
        .limit(3);

    setState(() {
      topByPremium = List<Map<String, dynamic>>.from(response);
      topByNOP = List<Map<String, dynamic>>.from(responseNOP);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🏆 Top Agent Rankings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedPeriod,
                items: const [DropdownMenuItem(value: 'Monthly', child: Text('Monthly')), DropdownMenuItem(value: 'Yearly', child: Text('Yearly'))],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedPeriod = value);
                    fetchTopAgents();
                  }
                },
              ),
            ],
          ),
        ),
        _buildTopSection("💰 Top Agents by Premium", topByPremium),
        const SizedBox(height: 12),
        _buildTopSection("🏅 Top Agents by NOP", topByNOP),
      ],
    );
  }

  Widget _buildTopSection(String title, List<Map<String, dynamic>> agents) {
    final List<String> emojis = ["🥇", "🥈", "🥉"];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (int i = 0; i < agents.length; i++)
            ListTile(
              leading: Text(emojis[i], style: const TextStyle(fontSize: 22)),
              title: Text(agents[i]['name'] ?? "Agent"),
              subtitle: Text("NOP: \${agents[i]['nop']} • Premium: ₹\${agents[i]['total_premium']}"),
            ),
        ],
      ),
    );
  }
}
