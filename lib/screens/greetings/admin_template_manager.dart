import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class AdminTemplateManager extends StatefulWidget {
  const AdminTemplateManager({super.key});

  @override
  State<AdminTemplateManager> createState() => _AdminTemplateManagerState();
}

class _AdminTemplateManagerState extends State<AdminTemplateManager> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> templates = [];
  bool loading = true;
  bool isUploading = false; // ✅ Spinner flag

  final templateNameController = TextEditingController();
  final titleController = TextEditingController();
  final categoryList = ['Birthday', 'Anniversary', 'Festival', 'Promo'];
  String selectedCategory = 'Birthday';

  String? uploadedImageURL;

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    final response = await supabase
        .from('greeting_template_master')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      templates = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  Future<void> pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // ✅ Upload to subfolder based on category
      final path = '${selectedCategory.toLowerCase()}/$uniqueName';

      try {
        setState(() => isUploading = true); // ✅ Show spinner

        final uploadedPath = await supabase.storage
            .from('greetings_templates')
            .uploadBinary(path, file.bytes!);

        final publicURL = supabase.storage
            .from('greetings_templates')
            .getPublicUrl(path);

        debugPrint('✅ Upload path: $uploadedPath');
        debugPrint('✅ Public URL: $publicURL');

        setState(() {
          uploadedImageURL = publicURL;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Image uploaded successfully!')),
        );
      } catch (error) {
        debugPrint('❌ Upload failed: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Upload failed: $error')),
        );
      } finally {
        setState(() => isUploading = false); // ✅ Hide spinner
      }
    }
  }

  Future<void> addTemplate() async {
    if (templateNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Template name required!')),
      );
      return;
    }

    if (uploadedImageURL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please upload an image first!')),
      );
      return;
    }

    await supabase.from('greeting_template_master').insert({
      'category': selectedCategory,
      'template_name': templateNameController.text.trim(),
      'image_url': uploadedImageURL,
      'requires_agent_photo': false,
      'default_enabled': true,
      'title': titleController.text.trim(),
      'design_type': 'image',
      'credits_required': 0,
      'created_by': supabase.auth.currentUser?.id,
    });

    templateNameController.clear();
    titleController.clear();
    uploadedImageURL = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Template added successfully!')),
    );

    fetchTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await supabase.from('greeting_template_master').delete().eq('id', id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Template deleted!')),
    );
    fetchTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Template Manager'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Template',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name (required)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedCategory,
              items: categoryList
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),

            // ✅ Show spinner or Upload button
            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: pickAndUploadImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Template Image'),
            ),

            if (uploadedImageURL != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.network(
                  uploadedImageURL!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),

            ElevatedButton.icon(
              onPressed: addTemplate,
              icon: const Icon(Icons.save),
              label: const Text('Add Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Existing Templates:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (var t in templates)
              Card(
                child: ListTile(
                  leading: t['image_url'] != null
                      ? Image.network(t['image_url'],
                      width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text('${t['template_name']} [${t['category']}]'),
                  subtitle: Text(t['title'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTemplate(t['id']),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
