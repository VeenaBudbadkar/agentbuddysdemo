import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'individual_policy_detail.dart';

class IndividualMemberPortfolio extends StatelessWidget {
  final String memberName;
  final List<Map<String, dynamic>> policies;
  const IndividualMemberPortfolio({super.key, required this.memberName, required this.policies,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$memberName's Policies"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Member Summary Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/default_avatar.png')),
                title: Text(memberName),
                subtitle: const Text("Age: 36 | Relationship: Self"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.call, color: Colors.green),
                    SizedBox(width: 12),
                    Icon(FontAwesomeIcons.whatsapp, color: Colors.teal),
                  ],
                ),
              ),
            ),
          ),

          // Divider Row with Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Policies: ${policies.length}", style: const TextStyle(color: Colors.white)),
                  Text(
                    "Premium: ₹${policies.fold(0.0, (sum, p) => sum + (p['installment_premium'] ?? 0).toDouble()).toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Bonus: ₹${policies.fold(0.0, (sum, p) => sum + (p['total_bonus'] ?? 0).toDouble()).toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),


            ),
          ),

          const SizedBox(height: 12),

          // Scrollable Policy Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: policies.length,
              itemBuilder: (context, index) {
                final policy = policies[index];
                return Column(
                  children: [
                    _policyCard(
                      context,
                      policy['plan_name'] ?? '',
                      policy['policy_number'] ?? '',
                      policy['sum_assured']?.toString() ?? '',
                      policy['premium_mode'] ?? '',
                      policy['installment_premium']?.toString() ?? '',
                      (policy['total_bonus'] ?? 0).toString(), // ✅ FIXED HERE
                      policy,
                    ),

                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),

          // InfoCard Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCard("Goal Mapping", Icons.flag),
                _infoCard("Investments", Icons.pie_chart),
                _infoCard("Premium Calendar", Icons.calendar_today),
                _infoCard("Cashflow", Icons.currency_exchange),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          // Navigation logic
        },
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

  Widget _policyCard(
      BuildContext context,
      String name,
      String policyNo,
      String sumAssured,
      String mode,
      String premium,
      String bonus,
      Map<String, dynamic> policy,
      ) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IndividualPolicyDetail(policyDetails: policy),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("Policy #: $policyNo", style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _policyItem("Sum Assured", sumAssured),
                  _policyItem("Mode", mode),
                  _policyItem("Premium", premium),
                  _policyItem("Bonus", bonus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _infoCard(String label, IconData icon) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.indigo),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
