import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lead_list_screen.dart';
import 'import_contacts_screen.dart'; // Your new custom multi-import screen

class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({super.key});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final supabase = Supabase.instance.client;

  // ✅ Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _status = 'Hot'; // Default status
  String? _nextAction; // Selected dropdown value
  DateTime? _selectedNAD;

  final List<String> nextActions = [
    'Call',
    'Meeting',
    'Follow-up',
    'Send Quotation',
    'Close Lead',
  ];

  final List<String> statuses = ['Hot', 'Warm', 'Cold'];

  // ✅ Pick single contact
  Future<void> pickSingleContact() async {
    if (await FlutterContacts.requestPermission()) {
      final Contact? contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        setState(() {
          _nameController.text = contact.displayName ?? '';
          _contactNumberController.text =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
          _emailController.text =
          contact.emails.isNotEmpty ? contact.emails.first.address : '';
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied!')),
      );
    }
  }

  // ✅ Multi-import: custom multi-picker
  Future<void> importMultipleContacts() async {
    final List<Contact>? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportContactsScreen()),
    );

    if (result != null && result.isNotEmpty) {
      final inserts = result.map((c) {
        return {
          'name': c.displayName,
          'contact_number': c.phones.isNotEmpty ? c.phones.first.number : '',
          'email': c.emails.isNotEmpty ? c.emails.first.address : '',
          'status': 'Hot',
          'agent_id': supabase.auth.currentUser?.id,
        };
      }).toList();

      await supabase.from('lead_master').insert(inserts);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Imported ${result.length} contacts!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LeadListScreen(filterStatus: "All")),
      );
    }
  }

  Future<void> _saveLead() async {
    if (_nameController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name & Contact Number are required!')),
      );
      return;
    }

    await supabase.from('lead_master').insert({
      'name': _nameController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'email': _emailController.text.trim(),
      'notes': _notesController.text.trim(),
      'status': _status,
      'next_action': _nextAction,
      'next_action_date': _selectedNAD?.toIso8601String(),
      'agent_id': supabase.auth.currentUser?.id,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Lead Saved!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LeadListScreen(filterStatus: "All")),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildStatusSegmented() {
    return Wrap(
      spacing: 8,
      children: statuses.map((status) {
        final isSelected = _status == status;
        return ChoiceChip(
          label: Text(status),
          selected: isSelected,
          selectedColor: status == 'Hot'
              ? Colors.red
              : status == 'Warm'
              ? Colors.orange
              : Colors.blue,
          onSelected: (_) {
            setState(() {
              _status = status;
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lead'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_contacts),
            tooltip: 'Multi-Import Contacts',
            onPressed: importMultipleContacts,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            const Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildStatusSegmented(),
            const SizedBox(height: 20),

            const Text(
              'Next Action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Next Action',
              ),
              value: _nextAction,
              items: nextActions.map((action) {
                return DropdownMenuItem<String>(
                  value: action,
                  child: Text(action),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _nextAction = value;
                });
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text('Next Action Date (NAD): '),
                Text(
                  _selectedNAD != null
                      ? _selectedNAD.toString().split(' ')[0]
                      : 'Select Date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedNAD = picked;
                      });
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveLead,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text(
                'Save Lead',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: pickSingleContact,
              icon: const Icon(Icons.contact_page),
              label: const Text("Import Single Contact"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
