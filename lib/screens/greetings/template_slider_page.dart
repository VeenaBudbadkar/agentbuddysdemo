import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hybrid_greeting_preview.dart';
import 'package:agentbuddys/screens/greetings/greeting_template_preview_screen.dart';

class TemplateSliderPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedClients;
  final Map<String, dynamic> agentProfile;

  const TemplateSliderPage({
    super.key,
    required this.selectedClients,
    required this.agentProfile,
  });

  @override
  State<TemplateSliderPage> createState() => _TemplateSliderPageState();
}

class _TemplateSliderPageState extends State<TemplateSliderPage> {
  final supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> groupedTemplates = {
    'marketing': [],
    'birthday': [],
    'anniversary': [],
    'festival': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    try {
      final response = await supabase
          .from('greeting_template_master')
          .select()
          .order('created_at', ascending: false);

      if (response is! List) return;

      for (var template in response) {
        final category = template['category']?.toString().toLowerCase() ?? 'other';
        if (groupedTemplates.containsKey(category)) {
          groupedTemplates[category]!.add(template);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching templates: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedTemplates.entries.map((entry) {
            final category = entry.key;
            final templates = entry.value;

            if (templates.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category[0].toUpperCase()}${category.substring(1)} Templates',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return GestureDetector(
                        onTap: () {
                          if (widget.selectedClients.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select at least one client!'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GreetingTemplatePreviewScreen(
                                template: template,
                                clientName: widget.selectedClients[0]['name'],
                                agentName: widget.agentProfile['name'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade200,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  template['image_url'] ?? '',
                                  height: 140,
                                  width: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 140,
                                        width: 250,
                                        color: Colors.grey,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                template['template_name'] ?? 'Unnamed Template',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}