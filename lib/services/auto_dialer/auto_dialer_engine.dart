import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/reports/campaign_funnel_report_screen.dart';

class AutoDialerEngine {
  final BuildContext context;
  final List<Map<String, dynamic>> contacts;
  final String campaignName;
  final List<String> triggerFilters;
  final String selectedStage; // ✅ You missed this field in your version

  int _currentIndex = 0;
  bool _isActive = false;

  AutoDialerEngine({
    required this.context,
    required this.contacts,
    required this.campaignName,
    required this.triggerFilters,
    required this.selectedStage, // ✅ Must be passed & defined
  });

  void start() {
    _currentIndex = 0;
    _isActive = true;
    _dialNext();
  }

  void _dialNext() async {
    if (!_isActive || _currentIndex >= contacts.length) {
      _showCampaignComplete();
      return;
    }

    final contact = contacts[_currentIndex];
    final number = contact['contact_number'] ?? '';

    if (number.isEmpty) {
      _currentIndex++;
      _dialNext();
      return;
    }

    final url = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void resumeWithFeedback(BuildContext feedbackContext) {
    final contact = contacts[_currentIndex];
    _showFeedbackDialog(feedbackContext, contact);
  }

  void _showFeedbackDialog(BuildContext feedbackContext, Map<String, dynamic> contact) {
    String? subAction = 'Campaign Call';
    DateTime selectedDate = DateTime.now();
    TextEditingController notesController = TextEditingController();

    List<String> subActionOptions = [
      'Interested',
      'Callback Later',
      'Not Interested',
      'Sale',
      'Custom'
    ];

    showDialog(
      context: feedbackContext,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text("Call Feedback & Next Action"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("Contact: ${contact['name']}"),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Outcome'),
                      value: subAction,
                      items: subActionOptions
                          .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => subAction = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Next Follow-up Date:"),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: feedbackContext,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Pick a Date"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.from('campaign_call_logs').insert({
                      'lead_id': contact['id'],
                      'campaign_name': campaignName,
                      'notes': notesController.text,
                      'outcome': subAction,
                      'followup_date': selectedDate.toIso8601String(),
                      'created_at': DateTime.now().toIso8601String(),
                      'trigger_filters': triggerFilters.join(', '),
                    });

                    // ✅ Mark as dialed in master — uses selectedStage correctly!
                    await Supabase.instance.client
                        .from(selectedStage == 'Lead' ? 'lead_master' : 'client_master')
                        .update({'is_dialed': true})
                        .eq('id', contact['id']);

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }

                    _currentIndex++;
                    _dialNext();
                  },
                  child: const Text("Save & Next"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCampaignComplete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🎉 Campaign Complete!"),
        content: const Text(
          "All calls done! Check the Funnel Report for results.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampaignFunnelReportScreen(
                    campaignName: campaignName,
                  ),
                ),
              );
            },
            child: const Text("View Report"),
          ),
        ],
      ),
    );
  }
}
