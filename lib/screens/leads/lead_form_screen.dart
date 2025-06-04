import 'package:flutter/material.dart';

class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({Key? key}) : super(key: key);

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _mobile;
  String? _email;
  String? _leadSource;
  String? _tag;

  final List<String> _leadSources = ['Referral', 'Social Media', 'Walk-In', 'Website', 'Cold Call'];
  final List<String> _tags = ['Hot', 'Warm', 'Cold'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Lead')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                  onSaved: (value) => _name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Please enter mobile' : null,
                  onSaved: (value) => _mobile = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Lead Source'),
                  items: _leadSources
                      .map((source) => DropdownMenuItem(value: source, child: Text(source)))
                      .toList(),
                  validator: (value) => value == null ? 'Please select source' : null,
                  onChanged: (value) => _leadSource = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: _tags
                      .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                      .toList(),
                  validator: (value) => value == null ? 'Please select tag' : null,
                  onChanged: (value) => _tag = value,
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // You can now send the data to Supabase or show a success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lead saved successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Lead'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
