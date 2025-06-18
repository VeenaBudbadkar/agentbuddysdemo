import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ImportContactsScreen extends StatefulWidget {
  const ImportContactsScreen({super.key});

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  List<Contact> _contacts = [];
  List<Contact> _selectedContacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied!')),
      );
    }
  }

  void _toggleSelect(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  Future<void> _importSelectedContacts() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 contact')),
      );
      return;
    }

    // Return selected contacts back to parent screen
    Navigator.pop(context, _selectedContacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Import Selected',
            onPressed: _importSelectedContacts,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          final isSelected = _selectedContacts.contains(contact);
          final phone = contact.phones.isNotEmpty
              ? contact.phones.first.number
              : 'No Number';
          return ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelect(contact),
            ),
            title: Text(contact.displayName),
            subtitle: Text(phone),
            onTap: () => _toggleSelect(contact),
          );
        },
      ),
    );
  }
}
