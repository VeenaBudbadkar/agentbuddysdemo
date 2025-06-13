import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgentProfileSettingsScreen extends StatefulWidget {
  const AgentProfileSettingsScreen({super.key});

  @override
  State<AgentProfileSettingsScreen> createState() => _AgentProfileSettingsScreenState();
}

class _AgentProfileSettingsScreenState extends State<AgentProfileSettingsScreen> {
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
      appBar: AppBar(title: const Text("My Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
