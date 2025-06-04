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

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription Activated!')),
    );

    final agentId = supabase.auth.currentUser?.id;
    final selectedPlan = plans.firstWhere(
          (plan) => response.orderId != null && plan['plan_name'] == response.orderId,
      orElse: () => {},
    );

    if (agentId != null && selectedPlan.isNotEmpty) {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 30));

      await supabase.from('agent_subscriptions').upsert({
        'agent_id': agentId,
        'plan_name': selectedPlan['plan_name'],
        'start_date': now.toIso8601String(),
        'end_date': expiry.toIso8601String(),
        'expiry_date': expiry.toIso8601String(),
        'status': 'active',
        'price': selectedPlan['price'],
        'usage_caps': selectedPlan['usage_caps'],
        'created_at': now.toIso8601String(),
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

  Future<bool> checkSubscriptionStatus() async {
    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) return false;

    final result = await supabase
        .from('agent_subscriptions')
        .select('status, expiry_date')
        .eq('agent_id', agentId)
        .maybeSingle();

    if (result == null || result['status'] != 'active') return false;

    final expiryDate = DateTime.tryParse(result['expiry_date']);
    return expiryDate != null && expiryDate.isAfter(DateTime.now());
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
