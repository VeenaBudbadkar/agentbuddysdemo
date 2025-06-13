import 'package:flutter/material.dart';

class PremiumServicesSection extends StatefulWidget {
  const PremiumServicesSection({super.key});

  @override
  State<PremiumServicesSection> createState() => _PremiumServicesSectionState();
}

class _PremiumServicesSectionState extends State<PremiumServicesSection> {
  String selectedMonth = 'June 2025';
  String _pressedButton = '';

  final List<String> monthOptions = [
    'June 2025',
    'July 2025',
    'August 2025',
    'September 2025',
  ];

  void _showAutoSendDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("🧠 Auto Send Reports"),
            content: const Text(
              "Free for first 5 reports.\nAfter that: 2 credits per report.\nProceed with auto-scheduling all reports?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Add auto-schedule logic here
                },
                child: const Text("Yes, Auto Send"),
              ),
            ],
          ),
    );
  }

  void _openServiceList(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Opening $serviceName List for $selectedMonth"),
      ),
    );
  }

  Widget _boldFlatButton(String label, Color baseColor, Color borderColor,
      IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedButton = label),
      onTapUp: (_) => setState(() => _pressedButton = ''),
      onTapCancel: () => setState(() => _pressedButton = ''),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 90,
        height: _pressedButton == label ? 84 : 90,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ROW 1: Heading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    "Premium Services",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ROW 2: Auto-Send + Icons + Month
            // ROW 2: Auto-Send + Icons + Month (COMPACT + RESPONSIVE)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Auto Send - Smaller width
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _showAutoSendDialog,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text("Auto", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  // Share, Download, Month Dropdown
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.grey),
                        onPressed: () {
                          // TODO: Direct share
                        },
                        tooltip: "Share",
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.grey),
                        onPressed: () {
                          // TODO: Download
                        },
                        tooltip: "Download",
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: selectedMonth,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.calendar_month),
                        items: monthOptions.map((month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedMonth = val ?? selectedMonth);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            const Divider(),

            // ROW 3: Bold Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _boldFlatButton(
                    "Cashflow",
                    const Color(0xFF1E90FF),
                    const Color(0xFF005BB5),
                    Icons.monetization_on,
                        () => _openServiceList("Cashflow"),
                  ),
                  _boldFlatButton(
                    "Title\nCheck",
                    const Color(0xFFFFC700),
                    const Color(0xFFB38B00),
                    Icons.assignment_turned_in,
                        () => _openServiceList("Title Verification"),
                  ),
                  _boldFlatButton(
                    "Premium",
                    const Color(0xFF5F3DC4),
                    const Color(0xFF2F1E77),
                    Icons.notifications_active,
                        () => _openServiceList("Premium Reminder"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}