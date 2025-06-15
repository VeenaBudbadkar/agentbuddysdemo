import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _error;

  Future<void> _sendResetEmail() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Reset link sent. Check your email!")),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Enter your email"),
            ),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isSending ? null : _sendResetEmail,
              child: _isSending
                  ? const CircularProgressIndicator()
                  : const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}
