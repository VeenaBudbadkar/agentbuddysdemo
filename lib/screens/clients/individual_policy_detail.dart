import 'package:flutter/material.dart';

class IndividualPolicyDetail extends StatelessWidget {
  final Map<String, dynamic> policyDetails;
  const IndividualPolicyDetail({super.key, required this.policyDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Policy Details", style: TextStyle(color: Colors.white)),
        actions: const [
          Icon(Icons.download, color: Colors.white),
          SizedBox(width: 12),
          Icon(Icons.share, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(radius: 32, backgroundImage: AssetImage('assets/default_avatar.png')),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(policyDetails['life_assured'] ?? 'Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        policyDetails['plan_name'] ?? 'Plan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Policy No.", policyDetails['policy_number']),
            _infoRow("Life Assured", policyDetails['life_assured']),
            _infoRow("Proposer", policyDetails['proposer_name']),
            _infoRow("DOB", policyDetails['dob']),
            _infoRow("INSURER", policyDetails['insurer']),
            _infoRow("Policy Start Date", policyDetails['policy_start_date']),
            _infoRow("Plan", policyDetails['plan_name']),
            _infoRow("Term", policyDetails['term']),
            _infoRow("PPT", policyDetails['ppt']),
            _infoRow("Sum Assured", policyDetails['sum_assured']),
            _infoRow("Premium Mode", policyDetails['premium_mode']),
            _infoRow("Inst. Premium", policyDetails['installment_premium']),
            _infoRow("GST", policyDetails['gst']),
            _infoRow("Annual Premium", policyDetails['annual_premium']),
            _infoRow("FUP Date", policyDetails['fup_date']),
            _infoRow("Policy Status", policyDetails['policy_status']),
            _infoRow("Nominee 1", policyDetails['nominee_1']),
            _infoRow("Nom 1 Share Holding", policyDetails['nominee_1_share']),
            _infoRow("Nominee 2", policyDetails['nominee_2']),
            _infoRow("Nom 2 Share Holding", policyDetails['nominee_2_share']),
            _infoRow("Maturity Date", policyDetails['maturity_date']),
            _infoRow("Total Prem Paid", policyDetails['total_premium_paid']),
            _infoRow("Total Bonus", policyDetails['total_bonus']),
            _infoRow("Surrender Value", policyDetails['surrender_value']),
            _infoRow("Loan Available", policyDetails['loan_available']),
            _infoRow("Projected Returns", policyDetails['projected_returns']),
            _infoRow("Current Risk Cover", policyDetails['current_risk_cover']),
            _infoRow("Accidental Cover", policyDetails['accidental_cover']),
            _infoRow("Other Rider", policyDetails['other_rider']),
            _infoRow("Agent Name", policyDetails['agent_name']),
            _infoRow("Agent Code", policyDetails['agent_code']),
            _infoRow("Servicing Branch", policyDetails['servicing_branch']),
            const SizedBox(height: 24),
            // Footer Agent Profile
            const Divider(),
            Row(
              children: [
                const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/default_avatar.png')),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(policyDetails['agent_name'] ?? 'Agent Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(policyDetails['agent_code'] ?? 'Agent Code'),
                    Text(policyDetails['agent_contact'] ?? 'Contact'),
                    Text(policyDetails['agent_email'] ?? 'Email'),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
