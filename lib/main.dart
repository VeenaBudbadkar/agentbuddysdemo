import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ IMPORTS
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/main_navigation.dart'; // ✅ USE THIS NOT dashboard_screen!
import 'screens/greetings/birthday_greeting_screen.dart';
import 'screens/greetings/anniversary_greeting_screen.dart';
import 'screens/calendar/calendar_view_screen.dart';
import 'screens/greetings/template_slider_page.dart';
import 'screens/voice_assistant_screen.dart';
import 'screens/monetization/credit_store_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/leads/import_contacts_screen.dart';
import 'auth_gate.dart'; // ✅ This should decide Login vs MainNavigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vbztfyhpbkvuvtatepmq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZienRmeWhwYmt2dXZ0YXRlcG1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2Mzg2MTIsImV4cCI6MjA2MzIxNDYxMn0.8NgXjCy25_owvjGa2lpv80takeYuOUpusHZf5anIsUY',
  );

  runApp(const AgentBuddysApp());
}

class AgentBuddysApp extends StatelessWidget {
  const AgentBuddysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgentBuddys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      // ✅ THIS IS THE FIX: Use AuthGate which returns MainNavigation after login
      home: const AuthGate(),

      // ✅ Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/import-contacts': (context) => const ImportContactsScreen(),
        '/greetings/birthday': (context) => const BirthdayGreetingScreen(),
        '/greetings/anniversary': (context) => const AnniversaryGreetingScreen(),
        '/calendar': (context) => const CalendarViewScreen(),
        '/greetings/templates': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TemplateSliderPage(
            agentProfile: args['agentProfile'],
            selectedClients: args['selectedClients'],
          );
        },

        '/subscription': (context) => const SubscriptionScreen(),
        '/voice-assistant': (context) => const VoiceAssistantScreen(),
        // ✅ DO NOT route to dashboard directly anymore!
        '/credit-store': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as bool;
          return CreditStoreScreen(isMembershipExpired: args);
        },
      },
    );
  }
}
