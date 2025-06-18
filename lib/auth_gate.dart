import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agentbuddys/screens/campaigns/campaign_list_screen.dart';
import 'package:agentbuddys/screens/auth/login_screen.dart'; // ✅
import 'package:agentbuddys/screens/dashboard/main_navigation.dart'; // ✅ THIS is the fix

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      debugPrint('🔥 AuthGate: event=$event, session=${session != null}');

      if (session == null) {
        _pushReplacement(const LoginScreen());
      } else {
        _pushReplacement(const MainNavigation()); // ✅ << THE REAL FIX!
      }
    });
  }

  void _pushReplacement(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
            (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
