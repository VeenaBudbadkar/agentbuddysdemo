import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignReportsScreen extends StatefulWidget {
  const CampaignReportsScreen({super.key});

  @override
  State<CampaignReportsScreen> createState() => _CampaignReportsScreenState();
}

class _CampaignReportsScreenState extends State<CampaignReportsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> campaigns = [];
  Map<String, double> outcomePie = {};
  List<Map<String, dynamic>> leaderboard = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    // ✅ Fetch raw logs, we’ll group in Dart.
    final rawLogs = await supabase
        .from('campaign_call_logs')
        .select('campaign_name, outcome, agent_id');

    final logs = List<Map<String, dynamic>>.from(rawLogs);

    // ✅ Group by campaign_name:
    final Map<String, int> campaignCount = {};
    for (var log in logs) {
      final name = log['campaign_name'] ?? 'Unknown';
      campaignCount[name] = (campaignCount[name] ?? 0) + 1;
    }

    // ✅ Group by outcome for pie chart:
    final Map<String, int> outcomeCount = {};
    for (var log in logs) {
      final outcome = log['outcome'] ?? 'Unknown';
      outcomeCount[outcome] = (outcomeCount[outcome] ?? 0) + 1;
    }

    // ✅ Group by agent for leaderboard:
    final Map<String, int> agentCount = {};
    for (var log in logs) {
      final agent = log['agent_id'] ?? 'Unknown';
      agentCount[agent] = (agentCount[agent] ?? 0) + 1;
    }

    setState(() {
      campaigns = campaignCount.entries
          .map((e) => {'campaign_name': e.key, 'count': e.value})
          .toList();

      outcomePie =
          outcomeCount.map((k, v) => MapEntry(k, v.toDouble()));

      leaderboard = agentCount.entries
          .map((e) => {'agent_id': e.key, 'count': e.value as int? ?? 0})
          .toList()
        ..sort((a, b) =>
            (b['count'] as int).compareTo(a['count'] as int));


      isLoading = false;
    });
  }

  Widget buildCampaignCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(data['campaign_name'] ?? 'Unnamed Campaign'),
        subtitle: Text("Total Calls: ${data['count']}"),
        trailing: const Icon(Icons.bar_chart),
      ),
    );
  }

  Widget buildAgentLeaderboard() {
    if (leaderboard.isEmpty) {
      return const Text("No agents yet.");
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final agent = leaderboard[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text("#${index + 1}"),
            ),
            title: Text("Agent ID: ${agent['agent_id'] ?? 'Unknown'}"),
            subtitle: Text("Total Calls: ${agent['count']}"),
          ),
        );
      },
    );
  }

  Widget buildPieChart() {
    if (outcomePie.isEmpty) {
      return const Text("No outcome data available.");
    }
    return PieChart(
      dataMap: outcomePie,
      chartType: ChartType.ring,
      chartValuesOptions: const ChartValuesOptions(
        showChartValuesInPercentage: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campaign Reports")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Campaign Summary",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...campaigns.map(buildCampaignCard).toList(),

              const SizedBox(height: 24),
              const Text(
                "Outcomes Breakdown",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: buildPieChart(),
              ),

              const SizedBox(height: 24),
              const Text(
                "Agent Leaderboard",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildAgentLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }
}
