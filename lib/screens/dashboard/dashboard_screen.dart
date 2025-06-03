// AgentBuddys Dashboard UI - Final Version with Bottom Navigation Integrated
import 'package:flutter/material.dart';
import 'package:agentbuddys/screens/leads/lead_list_screen.dart';
import 'package:agentbuddys/screens/clients/client_list_screen.dart';
import 'package:agentbuddys/screens/greetings/greeting_template_preview_screen.dart';
import '../greetings/template_slider_page.dart';
import 'package:your_project_name/screens/settings/settings_screen.dart';



void main() {
  runApp(const AgentBuddysApp());
}

class AgentBuddysApp extends StatelessWidget {
  const AgentBuddysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgentBuddys Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFd1f4ff),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const LeadListScreen(),
    const ClientListScreen(),
    const TemplateSliderPage(),
    const SettingsScreen(),
    const CreditStoreScreen(),
    Center(child: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Leads'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Clients'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Greetings'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}


class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Today - To Do List 😃", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 6),
            _buildTodaySection(),
            const SizedBox(height: 12),
            _buildKPISection(),
            const SizedBox(height: 12),
            _buildLeadTypeCard(),
            const SizedBox(height: 12),
            _buildAskBuddySection(),
            const SizedBox(height: 12),
            _buildTrainingSection(),
            const SizedBox(height: 12),
            _buildAddClientButton(),
            const SizedBox(height: 12),
            _buildTopPerformers(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Hello Mukesh", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Total Clients: 2000"),
                Text("Rank :"),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text("Total Credits - 100"),
                Text("Membership - Free", style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StatusCard(title: "Call", subtitle: "3 Appointment\n5 Follow-up", icon: Icons.phone, color: Colors.lightBlue),
                _StatusCard(title: "Meet", subtitle: "3 1st Appointment\n5 Follow-up", icon: Icons.video_call, color: Colors.cyan),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: Row(
                children: const [
                  Expanded(
                    child: _StatusButton(
                      label: "🎁 Birthdays/Anniversaries",
                      color: Colors.orangeAccent,
                      textSize: 12,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatusButton(
                      label: "📅 Add/ View Calendar",
                      color: Colors.yellow,
                      textSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text("👥 Leads\n20", textAlign: TextAlign.center),
            Text("📆 1st Appt\n5", textAlign: TextAlign.center),
            Text("📄 Policies\n3", textAlign: TextAlign.center),
            Text("💰 Premium\n₹1.5L", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadTypeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📊 Leads Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StatusButton(label: "🔥 Hot", color: Colors.red),
                _StatusButton(label: "🌤️ Warm", color: Colors.orange),
                _StatusButton(label: "❄️ Cold", color: Colors.lightBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskBuddySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("Ask Buddy 🤖", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Image(image: AssetImage('assets/agentbuddys_logo.png'), height: 50),
            SizedBox(height: 10),
            Text("Need help with objections? Ask me anything!"),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSection() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {},
      child: const Center(child: Text("📚 Training Sessions", style: TextStyle(color: Colors.white, fontSize: 16))),
    );
  }

  Widget _buildAddClientButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text("Add Leads+", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildTopPerformers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🏆 Top Performers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text("🔥 NOP Rankings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Column(children: const [
          _AgentRankCard(
            emoji: "🥇",
            name: "Snehalata Bhosale",
            branch: "91T",
            company: "LIC",
            location: "MH/Mumbai",
            metric: "NOP",
            value: "12",
          ),
          _AgentRankCard(
            emoji: "🥈",
            name: "Arjun Mehta",
            branch: "56B",
            company: "LIC",
            location: "MH/Pune",
            metric: "NOP",
            value: "10",
          ),
          _AgentRankCard(
            emoji: "🥉",
            name: "Neha Sharma",
            branch: "21M",
            company: "LIC",
            location: "MH/Nagpur",
            metric: "NOP",
            value: "9",
          ),
        ]),
        const SizedBox(height: 12),
        const Text("💰 Premium Rankings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Column(children: const [
          _AgentRankCard(
            emoji: "🥇",
            name: "Amit Singh",
            branch: "77X",
            company: "LIC",
            location: "GJ/Ahmedabad",
            metric: "Premium",
            value: "₹1.8L",
          ),
          _AgentRankCard(
            emoji: "🥈",
            name: "Priya Nair",
            branch: "11C",
            company: "LIC",
            location: "KA/Bangalore",
            metric: "Premium",
            value: "₹1.5L",
          ),
          _AgentRankCard(
            emoji: "🥉",
            name: "Ravi Kumar",
            branch: "63Y",
            company: "LIC",
            location: "TN/Chennai",
            metric: "Premium",
            value: "₹1.3L",
          ),
        ]),
      ],
    );
  }
}

class _AgentRankCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String branch;
  final String company;
  final String location;
  final String metric;
  final String value;

  const _AgentRankCard({
    required this.emoji,
    required this.name,
    required this.branch,
    required this.company,
    required this.location,
    required this.metric,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text("$name ($branch)", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$company | $location\n$metric: $value"),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final double textSize;

  const _StatusButton({required this.label, required this.color, this.textSize = 14});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () {},
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: textSize)),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 150,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
