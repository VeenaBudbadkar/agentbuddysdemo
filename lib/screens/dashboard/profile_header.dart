

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../subscription/subscription_screen.dart';
import '../monetization/credit_store_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ProfileHeader extends StatefulWidget {
  final String agentName;
  final String photoUrl;
  final int clientCount;
  final int creditBalance;
  final int monthlyRank;
  final String membershipPlan;

  const ProfileHeader({
    super.key,
    required this.agentName,
    required this.photoUrl,
    required this.clientCount,
    required this.creditBalance,
    required this.monthlyRank,
    required this.membershipPlan,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = false;
  bool isSubscriptionActive = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isVisible = true);
        _controller.forward();
      }
    });

    checkSubscription();
  }

  Future<void> checkSubscription() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('agent_subscriptions')
        .select('expiry_date')
        .eq('agent_id', userId)
        .maybeSingle();

    if (response == null || response['expiry_date'] == null) {
      setState(() => isSubscriptionActive = false);
    } else {
      final expiry = DateTime.tryParse(response['expiry_date']);
      if (expiry == null || expiry.isBefore(DateTime.now())) {
        setState(() => isSubscriptionActive = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isSubscriptionActive) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Membership Expired"),
            content: const Text("Please renew your membership to continue enjoying premium features."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Maybe Later"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text("Renew Now", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    });

    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 0, left: 0, right: 0),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : null,
                  backgroundColor: Colors.grey[200],
                  child: widget.photoUrl.isEmpty ? const Icon(Icons.person, size: 28) : null,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("👋 ${widget.agentName}",
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("Total Clients: ${widget.clientCount}",
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("Rank: ${widget.monthlyRank}",
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("MEM: ${isSubscriptionActive ? widget.membershipPlan : 'FREE'}",
                            style: const TextStyle(fontSize: 11.5, color: Colors.redAccent)),
                        const SizedBox(height: 4),
                        Text("Credits: ${widget.creditBalance}", style: const TextStyle(fontSize: 11.5)),
                        const SizedBox(height: 5),
                        FittedBox(
                          child: TextButton(
                            onPressed: () async {
                              await showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.upgrade),
                                        title: const Text("Upgrade Membership"),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SubscriptionScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                     ]
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text("Upgrade", style: TextStyle(fontSize: 11.5, color: Colors.deepPurple)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

