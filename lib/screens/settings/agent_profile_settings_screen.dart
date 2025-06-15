import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agentbuddys/screens/auth/landing_page.dart';
import 'package:agentbuddys/screens/auth/change_password_screen.dart';

class AgentProfileSettingsScreen extends StatefulWidget {
  const AgentProfileSettingsScreen({super.key});

  @override
  State<AgentProfileSettingsScreen> createState() =>
      _AgentProfileSettingsScreenState();
}

class _AgentProfileSettingsScreenState
    extends State<AgentProfileSettingsScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('agent_profile')
          .select('name')
          .eq('agent_id', agentId)
          .single();

      _nameController.text = data['name'] ?? '';
    } catch (e) {
      _error = "Failed to load profile";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('agent_profile')
          .update({'name': _nameController.text})
          .eq('agent_id', agentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      setState(() => _error = "Error updating profile");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Profile & Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile picture or icon
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),

            // Editable Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Your Name"),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Save Profile"),
            ),

            const SizedBox(height: 40),

            // 👉 Change Password Navigation
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text("Change Password"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 👉 Logout Button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
