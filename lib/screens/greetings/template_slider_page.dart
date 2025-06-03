import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'greeting_template_preview_screen.dart';

class TemplateSliderPage extends StatefulWidget {
  const TemplateSliderPage({super.key});

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

      final data = response as List;

      for (var template in data) {
        final category = template['category'] ?? 'other';
        if (groupedTemplates.containsKey(category)) {
          groupedTemplates[category]!.add(template);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching templates: $e');
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GreetingTemplatePreviewScreen(template: template),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(template['template_thumbnail'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                template['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
