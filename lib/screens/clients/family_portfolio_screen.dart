import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../clients/individual_member_portfolio.dart';

class FamilyPortfolioSummaryPage extends StatefulWidget {
  final String familyCode;
  const FamilyPortfolioSummaryPage({super.key, required this.familyCode});

  @override
  State<FamilyPortfolioSummaryPage> createState() => _FamilyPortfolioSummaryPageState();
}

class _FamilyPortfolioSummaryPageState extends State<FamilyPortfolioSummaryPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> familyMembers = [];
  bool loading = true;
  int totalPolicies = 0;
  int totalPremium = 0;

  @override
  void initState() {
    super.initState();
    fetchFamilyData();
  }

  Future<void> fetchFamilyData() async {
    setState(() => loading = true);
    try {
      final data = await supabase.from('client_master').select().eq('family_code', widget.familyCode);
      int policies = 0;
      double premium = 0.0;

      List<Map<String, dynamic>> fetchedMembers = [];
      for (final member in data) {
        List<dynamic> policyList = [];
        try {
          policyList = await supabase
              .from('policy_master')
              .select()
              .eq('client_id', member['id']);

        } catch (_) {
          policyList = [];
        }

        final int memberPolicies = policyList.length;
        final double memberPremium = policyList.fold<double>(0.0, (sum, p) => sum + (p['premium_amount'] ?? 0).toDouble());

        final memberMap = {
          'id': member['id'],
          'first_name': member['first_name'] ?? 'Name Awaited',
          'last_name': member['last_name'] ?? '',
          'contact_number': member['contact_number'] ?? 'Mobile Awaited',
          'email': member['email'] ?? 'Email Awaited',
          'profile_photo_url': member['profile_photo_url'] ?? '',
          'family_code': member['family_code'] ?? '',
          'age': member['age'] ?? '-',
          'education': member['education'] ?? 'Not Available',
          'occupation': member['occupation'] ?? 'Not Available',
          'is_head_of_family': member['is_head_of_family'] ?? false,
          'policies': policyList,
          'premium': memberPremium,
          'bonus': policyList.fold(0.0, (sum, p) => sum + (p['total_bonus'] ?? 0).toDouble()),

        };

        policies += memberPolicies;
        premium += memberPremium;

        fetchedMembers.add(memberMap);
      }

      setState(() {
        familyMembers = fetchedMembers;
        totalPolicies = policies;
        totalPremium = premium.toInt();
        loading = false;
      });
    } catch (e) {
      print('Error loading family data: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final uri = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openMemberPortfolio(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndividualMemberPortfolio(
          memberName: member['first_name'] ?? "Member",
          policies: (member['policies'] as List<dynamic>).cast<Map<String, dynamic>>(),




        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final head = familyMembers.firstWhere(
          (m) => m['is_head_of_family'] == true,
      orElse: () => familyMembers.isNotEmpty ? familyMembers[0] : {
        'first_name': 'Name Awaited',
        'last_name': '',
        'contact_number': 'Mobile Awaited',
        'email': 'Email Awaited',
        'profile_photo_url': '',
        'education': 'Not Available',
        'occupation': 'Not Available'
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Family LIC Portfolio")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: head['profile_photo_url'] != ''
                        ? NetworkImage(head['profile_photo_url'])
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${head['first_name']} ${head['last_name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => _launchWhatsApp(head['contact_number']),
                          child: Text("📞 ${head['contact_number']}", style: const TextStyle(color: Colors.blueAccent)),
                        ),
                        GestureDetector(
                          onTap: () => _launchEmail(head['email']),
                          child: Text("📧 ${head['email']}", style: const TextStyle(color: Colors.blueAccent)),
                        ),
                        Text("🎓 ${head['education']}", style: const TextStyle(color: Colors.grey)),
                        Text("💼 ${head['occupation']}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("View Report"),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("Family Member Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  if (index < familyMembers.length) {
                    final m = familyMembers[index];
                    return GestureDetector(
                      onTap: () => _openMemberPortfolio(m),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: m['profile_photo_url'] != ''
                                  ? NetworkImage(m['profile_photo_url'])
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            ),
                            const SizedBox(height: 8),
                            Text(m['first_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Age: ${m['age']}", style: const TextStyle(fontSize: 12)),
                            Text("${m['policies']} Policies", style: const TextStyle(fontSize: 12)),
                            Text("₹${m['premium'].toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(child: Text("Add members soon")),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard("Total Policies", totalPolicies.toString(), Icons.assignment),
                _infoCard("Premium", "₹$totalPremium", Icons.currency_rupee),
                _infoCard("Bonus", "Coming Soon", Icons.card_giftcard),
                _infoCard("Last Policy", "Coming Soon", Icons.access_time),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard("Goal Mapping", "Explore", Icons.flag),
                _infoCard("Investments", "View", Icons.trending_up),
                _infoCard("Premium Calendar", "Plan", Icons.calendar_today),
                _infoCard("Digi Book", "Access", Icons.book),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Leads"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Clients"),
          BottomNavigationBarItem(icon: Icon(Icons.cake), label: "Greetings"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.teal),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
