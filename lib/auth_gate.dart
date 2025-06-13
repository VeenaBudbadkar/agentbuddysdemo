import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard/main_navigation.dart';
import 'screens/auth/landing_page.dart';
import 'screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;


    debugPrint("🔍 Supabase currentUser = $session");

    if (session == null) {
      debugPrint("👉 No session → Going to LandingPage");
      return const LandingPage();
    } else {
      debugPrint("👉 Active session → Going to MainNavigation");
      debugPrint("✅ Returning MainNavigation");
      return const MainNavigation();

    }

  }
  }

