import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/greetings/birthday_greeting_screen.dart';
import 'screens/greetings/anniversary_greeting_screen.dart';
import 'screens/calendar/calendar_view_screen.dart'; // Placeholder for future
import 'screens/greetings/template_slider_page.dart'; // 👈 add this line
import 'package:agentbuddys/screens/voice_assistant_screen.dart';
import 'package:agentbuddys/screens/monetization/credit_store_screen.dart';
import 'package:agentbuddys/screens/subscription/subscription_screen.dart';





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
      home: const LandingPage(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/greetings/birthday': (context) => const BirthdayGreetingScreen(),
        '/greetings/anniversary': (context) => const AnniversaryGreetingScreen(),
        '/calendar': (context) => const CalendarViewScreen(),
        '/greetings/templates': (context) => const TemplateSliderPage(),
        '/credit-store': (context) => const CreditStoreScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/voice-assistant': (context) => const VoiceAssistantScreen(),



      },
    );
  }
}
