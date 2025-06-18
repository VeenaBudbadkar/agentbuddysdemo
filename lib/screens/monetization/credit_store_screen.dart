import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CreditStoreScreen extends StatefulWidget {
  final bool isMembershipExpired;

  const CreditStoreScreen({super.key, required this.isMembershipExpired});



  @override
  State<CreditStoreScreen> createState() => _CreditStoreScreenState();
}

class _CreditStoreScreenState extends State<CreditStoreScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> creditPacks = [];
  bool isLoading = true;
  bool offerShown = false;
  int currentCredits = 0;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    fetchCreditPackages();
    fetchAgentCredits();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    Future.delayed(const Duration(milliseconds: 600), showFestivalOfferDialog);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> fetchCreditPackages() async {
    final response = await supabase.from('credit_packages').select();
    setState(() {
      creditPacks = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> fetchAgentCredits() async {
    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) return;

    final response = await supabase
        .from('agent_credits')
        .select('credits')
        .eq('agent_id', agentId)
        .maybeSingle();

    if (response != null && response['credits'] != null) {
      setState(() {
        currentCredits = response['credits'] as int;
      });
    }
  }

  Future<void> deductCreditsIfEnough(int amount) async {
    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) return;

    final response = await supabase
        .from('agent_credits')
        .select('credits')
        .eq('agent_id', agentId)
        .maybeSingle();

    if (response == null || response['credits'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No credit data found.')),
      );
      return;
    }

    final currentCredits = response['credits'] as int;

    if (currentCredits < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Not enough credits!')),
      );
      return;
    }

    if (widget.isMembershipExpired) {
      // disable purchase buttons or show extra alert
    }


    final updatedCredits = currentCredits - amount;

    await supabase
        .from('agent_credits')
        .update({'credits': updatedCredits})
        .eq('agent_id', agentId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
          '✅ $amount credits deducted. New balance: $updatedCredits')),
    );
  }

  void showFestivalOfferDialog() {
    if (!offerShown) {
      setState(() => offerShown = true);
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                "🎉 Festival Dhamaka Offer!",
                style: TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Get 2000 credits for just ₹1650!"),
                  SizedBox(height: 12),
                  Text("+ Bonus 20% extra credits 💥",
                      style: TextStyle(color: Colors.green)),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Festival Dhamaka Selected!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Buy Now – ₹1650",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await deductCreditsIfEnough(99);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Use 99 Credits",
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Maybe Later"),
                    ),

                  ],
                ),
              ],
            ),
      );
    }
  }

  void showBulkMessageCreditPopup(BuildContext context, int selectedCount) {
    if (selectedCount > 5) {
      showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              title: const Text("Bulk Message Alert"),
              content: const Text(
                "You're using bulk messaging like a pro!\n"
                    "Let it go automatically for the next 30 days — use just 99 credits.\n"
                    "No more tapping ‘Send’ again!",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Maybe Later"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final agentId = supabase.auth.currentUser?.id;
                    if (agentId == null) return;

                    final response = await supabase
                        .from('agent_credits')
                        .select('credits')
                        .eq('agent_id', agentId)
                        .single();

                    final currentCredits = response['credits'] ?? 0;

                    if (currentCredits < 99) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "❌ Not enough credits. Please buy more."),
                        ),
                      );
                      return;
                    }

                    final updatedCredits = currentCredits - 99;

                    await supabase
                        .from('agent_credits')
                        .update({'credits': updatedCredits})
                        .eq('agent_id', agentId);

                    await supabase.from('credit_transactions').insert({
                      'agent_id': agentId,
                      'credits_used': 99,
                      'type': 'automation_upgrade',
                      'used_for': '30-day automation',
                    });

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "✅ Auto Messaging Activated for 30 Days!"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text("Use 99 Credits"),
                ),
              ],
            ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Payment Successful! Credits will be added shortly.')),
    );

    final agentId = supabase.auth.currentUser?.id;
    if (agentId == null) return;

    final selectedPack = creditPacks.firstWhere((pack) =>
        pack['package_name'].toString().toLowerCase().contains("festival"),
        orElse: () => {});
    if (selectedPack.isNotEmpty) {
      final int creditsToAdd = selectedPack['credits'];
      final int bonus = selectedPack['bonus'] ?? 0;

      await supabase
          .from('agent_credits')
          .upsert({'agent_id': agentId, 'credits': creditsToAdd + bonus},
          onConflict: 'agent_id');

      await supabase.from('credit_transactions').insert({
        'agent_id': agentId,
        'credits_used': -(creditsToAdd + bonus),
        'type': 'purchase',
        'used_for': selectedPack['package_name'],
      });

      fetchAgentCredits();
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

  void startRazorpayPayment(Map<String, dynamic> pack) {
    var options = {
      'key': 'rzp_test_your_api_key_here',
      'amount': pack['price_inr'] * 100,
      'name': 'AgentBuddys',
      'description': pack['package_name'],
      'prefill': {
        'contact': '9999999999',
        'email': 'agent@example.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Credits'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Chip(
              label: Text('Credits: $currentCredits'),
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ MEMBERSHIP EXPIRED BANNER
          if (widget.isMembershipExpired)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.all(12),
              child: const Text(
                '⚠️ Membership Expired! Renew now to unlock full features!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          // ✅ MAIN CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: creditPacks.length,
              itemBuilder: (context, index) {
                final pack = creditPacks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack['package_name'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Credits: ${pack['credits']}'),
                        Text('Price: ₹${pack['price_inr']}'),
                        if (pack['bonus'] != null && pack['bonus'] > 0)
                          Text(
                            'Bonus: +${pack['bonus']} credits',
                            style: const TextStyle(color: Colors.green),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => startRazorpayPayment(pack),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple),
                          child: const Text('Buy Now'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}