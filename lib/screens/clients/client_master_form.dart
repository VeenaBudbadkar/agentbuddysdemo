// Full and Final Code for ClientMasterForm with all requested features and missing fixes added
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ClientMasterForm extends StatefulWidget {
  final Map<String, dynamic>? prefilledLead;

  const ClientMasterForm({super.key, this.prefilledLead});

  @override
  State<ClientMasterForm> createState() => _ClientMasterFormState();
}

class _ClientMasterFormState extends State<ClientMasterForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  String? honorific, firstName, middleName, lastName, gender, mobile, email;
  String? education, occupation, income, language, religion, pan, aadhaar, area, address;
  String? leadId, notes, voiceNote, bio;
  DateTime? dob, anniversary;
  bool isHead = false;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> educationOptions = [
    'Below 10th', '10th Pass', '12th Pass', 'Graduate', 'Post-Graduate', 'Professional'
  ];
  final List<String> occupationOptions = [
    'Student', 'Salaried', 'Business', 'Self-Employed', 'Retired', 'Homemaker', 'Other'
  ];
  final List<String> honorificOptions = ['Mr.', 'Mrs.', 'Smt.', 'Shri', 'Mast.', 'Ms.', 'Dr.'];
  final List<String> religionOptions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Other'];
  final List<String> languageOptions = ['Hindi', 'English', 'Marathi', 'Gujarati', 'Tamil', 'Other'];
  final List<Map<String, dynamic>> familyMembers = [];

  String capitalize(String input) {
    return input.trim().isEmpty ? '' : input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.prefilledLead != null) {
      firstName = capitalize(widget.prefilledLead!['first_name'] ?? '');
      lastName = capitalize(widget.prefilledLead!['last_name'] ?? '');
      mobile = widget.prefilledLead!['mobile'];
      email = widget.prefilledLead!['email'];
      leadId = widget.prefilledLead!['lead_id'];
      notes = widget.prefilledLead!['notes'];
    }
  }

  void showAddFamilyMemberDialog() {
    String? fName, mName, lName, gender, relation, honorific, education, occupation, income, bio;
    DateTime? dob;
    bool isHeadOfFamily = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Family Member"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (val) => fName = capitalize(val),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Middle Name'),
                  onChanged: (val) => mName = capitalize(val),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (val) => lName = capitalize(val),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'DOB (yyyy-mm-dd)'),
                  onChanged: (val) => setState(() => dob = DateTime.tryParse(val)),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: genderOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => gender = val,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Relation'),
                  items: ['Father', 'Mother', 'Child', 'Spouse', 'Sibling', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => relation = val,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Education'),
                  items: educationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => education = val,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Occupation'),
                  items: occupationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => occupation = val,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Income'),
                  onChanged: (val) => income = val,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Bio'),
                  onChanged: (val) => bio = val,
                ),
                CheckboxListTile(
                  title: const Text("Head of Family"),
                  value: isHeadOfFamily,
                  onChanged: (val) => setState(() => isHeadOfFamily = val ?? false),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (fName != null && dob != null && gender != null && relation != null) {
                  setState(() => familyMembers.add({
                    'name': capitalize(fName!),
                    'middle_name': capitalize(mName ?? ''),
                    'last_name': capitalize(lName ?? ''),
                    'age': '${DateTime.now().year - dob!.year}',
                    'gender': gender!,
                    'relation': relation!,
                    'status': 'Service',
                    'isHead': isHeadOfFamily,
                    'education': education,
                    'occupation': occupation,
                    'income': income,
                    'bio': bio,
                  }));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFamilyTable() {
    if (familyMembers.isEmpty) return const Text('No family members added yet.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Age')),
          DataColumn(label: Text('Gender')),
          DataColumn(label: Text('Relation')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Head')),
        ],
        rows: familyMembers.map((member) => DataRow(cells: [
          DataCell(Text('${member['name']} ${member['middle_name'] ?? ''} ${member['last_name'] ?? ''}')),
          DataCell(Text(member['age'].toString())),
          DataCell(Text(member['gender'])),
          DataCell(Text(member['relation'])),
          DataCell(Text(member['status'])),
          DataCell(Icon(member['isHead'] == true ? Icons.star : Icons.star_border)),
        ])).toList(),
      ),
    );
  }

// Existing saveClientToSupabase remains unchanged and is included
// Other parts of build remain unchanged
// Only modal behavior and family table rendering updated above
  Future<void> saveClientToSupabase() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('client_master').insert({
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'honorific': honorific,
        'mobile': mobile,
        'email': email,
        'gender': gender,
        'dob': dob?.toIso8601String(),
        'is_head': isHead,
        'education': education,
        'occupation': occupation,
        'income': income,
        'language': language,
        'religion': religion,
        'pan': pan,
        'aadhaar': aadhaar,
        'anniversary': anniversary?.toIso8601String(),
        'area': area,
        'address': address,
        'notes': notes,
        'voice_note': voiceNote
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client saved to Supabase!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client Master")),
      floatingActionButton: FloatingActionButton(
        onPressed: saveClientToSupabase,
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Client Family Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: showAddFamilyMemberDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("ADD", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 4,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  DropdownButton<String>(
                    value: honorific,
                    hint: const Text('Mr.'),
                    onChanged: (val) => setState(() => honorific = val),
                    items: honorificOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'First Name'),
                      onChanged: (val) => firstName = val,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Middle Name'),
                      onChanged: (val) => middleName = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      onChanged: (val) => lastName = val,
                    ),
                  ),
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mobile'),
                onChanged: (val) => mobile = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (val) => email = val,
              ),
              CheckboxListTile(
                title: const Text("Family Head"),
                value: isHead,
                onChanged: (val) => setState(() => isHead = val ?? false),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Personal Details"),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'PAN'),
                                onChanged: (val) => pan = val,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Aadhaar'),
                                onChanged: (val) => aadhaar = val,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Religion'),
                                onChanged: (val) => religion = val,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Language'),
                                onChanged: (val) => language = val,
                              ),
                              TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(labelText: 'Wedding Anniversary'),
                                controller: TextEditingController(
                                  text: anniversary == null ? '' : DateFormat.yMMMd().format(anniversary!),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime(2000),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => anniversary = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                        ],
                      ),
                    ),
                    child: const Text("Personal Details"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Address & Notes"),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Area'),
                                onChanged: (val) => area = val,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Address'),
                                onChanged: (val) => address = val,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Lead Notes'),
                                initialValue: notes,
                                maxLines: 3,
                                onChanged: (val) => notes = val,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                        ],
                      ),
                    ),
                    child: const Text("Address & Notes"),
                  ),
                ],
              ),

              DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Age')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('Rel')),
                  DataColumn(label: Text('Status')),
                ],
                rows: familyMembers.map((member) {
                  return DataRow(cells: [
                    DataCell(Text(member['name'] ?? '')),
                    DataCell(Text(member['age'] ?? '')),
                    DataCell(Text(member['gender'] ?? '')),
                    DataCell(Text(member['relation'] ?? '')),
                    DataCell(Chip(
                      label: Text(member['status'] == 'Client' ? 'Client' : 'Service'),
                      backgroundColor: member['status'] == 'Client'
                          ? Colors.green[100]
                          : Colors.orange[100],
                    )),
                  ]);
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

