import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GreetingTemplatePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> template;

  const GreetingTemplatePreviewScreen({required this.template, super.key});

  @override
  State<GreetingTemplatePreviewScreen> createState() =>
      _GreetingTemplatePreviewScreenState();
}

class _GreetingTemplatePreviewScreenState
    extends State<GreetingTemplatePreviewScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> clients = [];
  Map<String, dynamic>? selectedClient;
  bool isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    final response = await supabase
        .from('client_master')
        .select('id, full_name, client_salutation, contact_number, email');

    setState(() {
      clients = List<Map<String, dynamic>>.from(response);
      isLoadingClients = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final fullImageUrl = template['template_full_image'] ?? '';
    final title = template['title'] ?? 'Greeting';
    final credits = template['credits_required'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.network(
              fullImageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 80),
            ),
          ),
          if (isLoadingClients)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                value: selectedClient,
                decoration: const InputDecoration(
                  labelText: 'Select Client',
                  border: OutlineInputBorder(),
                ),
                items: clients.map((client) {
                  return DropdownMenuItem(
                    value: client,
                    child: Text(client['client_salutation'] ?? client['full_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClient = value;
                  });
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text("Send Manually (Free)"),
                  onPressed: selectedClient == null
                      ? null
                      : () => _showSendOptions(context, template, selectedClient!),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: Text("Send Automatically for $credits Credits"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Coming Soon: Auto-send")),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSendOptions(BuildContext context, Map<String, dynamic> template,
      Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.whatsapp),
              title: const Text('Send via WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _sendViaWhatsApp(template, client);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send via Email'),
              onTap: () {
                Navigator.pop(ctx);
                _sendViaEmail(template, client);
              },
            ),
          ],
        );
      },
    );
  }

  void _sendViaWhatsApp(
      Map<String, dynamic> template, Map<String, dynamic> client) async {
    final imageUrl = template['template_full_image'];
    final title = template['title'] ?? 'Greeting';
    final salutation = client['client_salutation'] ?? client['full_name'];

    final message = Uri.encodeComponent(
        "🎉 $title 🎉\n\nDear $salutation,\nHere's a greeting specially for you:\n$imageUrl");

    final whatsappUrl = Uri.parse("https://wa.me/?text=$message");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch WhatsApp");
    }
  }

  void _sendViaEmail(
      Map<String, dynamic> template, Map<String, dynamic> client) async {
    final subject = Uri.encodeComponent(template['title'] ?? 'Greeting');
    final imageUrl = template['template_full_image'];
    final salutation = client['client_salutation'] ?? client['full_name'];

    final body = Uri.encodeComponent(
        "Dear $salutation,\n\nHere's a greeting just for you:\n\n$imageUrl");

    final emailUrl = Uri.parse("mailto:?subject=$subject&body=$body");

    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch Email client");
    }
  }
}
