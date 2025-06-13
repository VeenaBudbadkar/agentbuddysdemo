import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/main_navigation.dart';
import 'landing_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // If not logged in, show LandingPage
    if (session == null) {
      return const LandingPage();
    }

    // If logged in, go to Dashboard with Bottom Nav
    return const MainNavigation();
  }
}
