import 'package:flutter/material.dart';

class KPIDashboardCarousel extends StatefulWidget {
  const KPIDashboardCarousel({super.key});

  @override
  State<KPIDashboardCarousel> createState() => _KPIDashboardCarouselState();
}

class _KPIDashboardCarouselState extends State<KPIDashboardCarousel> {
  String selectedPeriod = 'This Month';
  String selectedScope = 'My Stats';
  bool showComparison = true;

  final int leadsCurrent = 48;
  final int leadsPrevious = 35;
  final int appointmentsCurrent = 28;
  final int appointmentsPrevious = 25;
  final int policiesCurrent = 15;
  final int policiesPrevious = 18;
  final double premiumCurrent = 65000;
  final double premiumPrevious = 54000;
  final int rank = 4;
  final int lastRank = 6;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Label - Now properly aligned to left
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8), // Added left padding
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50]!.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "KPI",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text("📊"),
                  ],
                ),
              ),
            ),

            // Rest of your existing code remains exactly the same
            Card(
              color: Colors.grey[100],
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Tooltip(
                            message: 'Select export format',
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: Container(),
                              hint: const Text("📁 Export"),
                              items: ['This Month', 'Last Month', 'Quarterly']
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Exporting report for: $val')),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Tooltip(
                            message: 'Change the KPI time range',
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: Container(),
                              value: selectedPeriod,
                              items: ['This Month', 'Last Month', 'Quarter', '6 Months', 'This Year']
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedPeriod = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Tooltip(
                            message: 'View your performance or compare with top agents',
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: Container(),
                              value: selectedScope,
                              items: ['My Stats', 'Top Agents']
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedScope = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Share functionality coming soon!")));
                              },
                              tooltip: 'Share KPI Report',
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Download functionality coming soon!")));
                              },
                              tooltip: 'Download KPI Report',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text("Compare", style: TextStyle(fontSize: 12)),
                            Switch(
                              value: showComparison,
                              onChanged: (val) => setState(() => showComparison = val),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildKpiCard("Leads Added", leadsCurrent, leadsPrevious, "", Icons.group_add, Colors.blue),
                  _buildKpiCard("1st Appointments", appointmentsCurrent, appointmentsPrevious, "", Icons.phone_in_talk, Colors.green),
                  _buildKpiCard("Policies Done", policiesCurrent, policiesPrevious, "", Icons.assignment_turned_in, Colors.orange),
                  _buildKpiCard("Premium", premiumCurrent.toInt(), premiumPrevious.toInt(), "₹", Icons.currency_rupee, Colors.purple),
                  _buildKpiCard("Rank", rank, lastRank, "#", Icons.emoji_events, Colors.red),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, int current, int previous, String unit, IconData icon, Color color) {
    final int diff = current - previous;
    final String percent = (previous == 0)
        ? (current > 0 ? "∞" : "0%")
        : ((diff / previous) * 100).toStringAsFixed(1) + "%";

    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: current),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, _) => Text(
              "$unit$value",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          if (showComparison) ...[
            Text("Previous: $unit$previous", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                  begin: 0,
                  end: (previous == 0 && current == 0)
                      ? 0.0
                      : (previous == 0 && current > 0)
                      ? 1.0
                      : (current / previous).clamp(0.0, 2.0)
              ),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(current >= previous ? Colors.green : Colors.red),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              diff >= 0 ? "📈 +$diff ($percent)" : "📉 $diff ($percent)",
              style: TextStyle(fontSize: 12, color: diff >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
            ),
          ]
        ],
      ),
    );
  }
}