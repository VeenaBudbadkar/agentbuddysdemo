// This is the starting point for Subscription Logic UI + Backend Setup
// Step-by-step tasks we'll execute:
// 1. Create `subscription_plans` table in Supabase (already done)
// 2. Build UI to show plans (Smart / Power / Elite)
// 3. Add Razorpay integration for plan payments
// 4. Store subscription details in a new table `agent_subscriptions`
// 5. Create logic to activate plan benefits (messages, voice, SEO)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Razorpay _razorpay;
  List<Map<String, dynamic>> plans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final response = await supabase.from('subscription_plans').select();
    setState(() {
      plans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription Activated!')),
    );
    final agentId = supabase.auth.currentUser?.id;
    if (agentId != null) {
      final selectedPlan = plans.firstWhere((p) => p['plan_name'] == response.orderId);
      final usageCaps = selectedPlan['usage_caps'] ?? '';
      final expiryDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();

      await supabase.from('agent_subscriptions').upsert({
        'agent_id': agentId,
        'plan_name': response.orderId,
        'activated_on': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate,
        'status': 'active',
        'usage_caps': usageCaps
      }, onConflict: 'agent_id');

    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet Selected: ${response.walletName}')),
    );
  }

  void startSubscriptionPayment(Map<String, dynamic> plan) {
    var options = {
      'key': 'rzp_test_your_api_key_here',
      'amount': plan['price'] * 100,
      'name': 'AgentBuddys',
      'description': plan['plan_name'],
      'prefill': {
        'contact': '9999999999',
        'email': 'agent@example.com',
      },
    };
    _razorpay.open(options);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          final List<String> features = (plan['inclusions'] as String).split('<br>');
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['plan_name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Price: ₹${plan['price']} / month'),
                  const SizedBox(height: 8),
                  ...features.map((f) => Text(f.trim())).toList(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => startSubscriptionPayment(plan),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Subscribe'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
