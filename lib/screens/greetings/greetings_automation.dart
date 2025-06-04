// greetings_automation.dart - Enhanced with Auto-Funnel Based on Client Religion

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:your_app/utils/subscription_guard.dart';

class GreetingsAutomation extends StatefulWidget {
  const GreetingsAutomation({super.key});

  Future<void> sendAutoGreetingWithCredit({
    required String type, // 'birthday' etc.
    required String templateId,
    required int creditCost,
  }) async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;

    final today = DateTime.now();
    final endDate = today.add(const Duration(days: 7));
    final range = '${today.toIso8601String()},${endDate.toIso8601String()}';

    final response = await Supabase.instance.client
        .rpc('auto_send_greetings', params: {
      'p_agent_id': agentId,
      'p_type': type,
      'p_date_range': '[${today.toIso8601String()},${endDate.toIso8601String()}]',
      'p_greeting_template_id': templateId,
      'p_credit_cost': creditCost,
    });

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Greetings sent, credits deducted!')),
      );
    }
  }

  @override
  State<GreetingsAutomation> createState() => _GreetingsAutomationState();
}

class _GreetingsAutomationState extends State<GreetingsAutomation> {
  String greetingType = 'Birthday';
  DateTime? startDate;
  DateTime? endDate;
  String? selectedTemplate;
  String? clientReligion;

  final List<String> religionOptions = [
    'All', 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Parsi'
  ];

  final List<String> birthdayTemplates = [
    '🎂 Happy Birthday Template 1',
    '🎂 Happy Birthday Template 2',
    '🎂 Happy Birthday Template 3',
    '🎂 Happy Birthday Template 4',
    '🎂 Happy Birthday Template 5',
  ];

  final List<String> anniversaryTemplates = [
    '💍 Anniversary Template 1',
    '💍 Anniversary Template 2',
    '💍 Anniversary Template 3',
    '💍 Anniversary Template 4',
    '💍 Anniversary Template 5',
  ];

  final Map<String, List<String>> festivalTemplatesByReligion = {
    'Hindu': [
      '🪁 Makar Sankranti / Lohri / Pongal',
      '📚 Vasant Panchami',
      '🕉️ Maha Shivaratri',
      '🌈 Holi',
      '🛕 Ram Navami',
      '🐒 Hanuman Jayanti',
      '🔗 Raksha Bandhan',
      '🎉 Janmashtami',
      '🐘 Ganesh Chaturthi',
      '🪔 Navratri / Durga Puja',
      '🏹 Dussehra',
      '🎆 Diwali',
      '🌅 Chhath Puja',
      '💫 Karva Chauth'
    ],
    'Muslim': [
      '🕌 Eid-ul-Fitr',
      '🐐 Bakrid (Eid-ul-Adha)',
      '🖤 Muharram',
      '📿 Milad-un-Nabi'
    ],
    'Christian': [
      '🎄 Christmas',
      '✝️ Good Friday',
      '🌅 Easter'
    ],
    'Sikh': [
      '🧣 Guru Nanak Jayanti',
      '🌾 Baisakhi',
      '🔥 Lohri (Sikh)'
    ],
    'Jain': [
      '🚩 Mahavir Jayanti',
      '🛐 Paryushana'
    ],
    'Buddhist': ['🪷 Buddha Purnima'],
    'Parsi': ['🌸 Navroz (Nowruz)'],
    'All': [
      '🇮🇳 Republic Day',
      '🕊️ Independence Day',
      '🕯️ Gandhi Jayanti',
      '👩‍🏫 Teachers\' Day',
      '🩺 Doctors\' Day',
      '🧠 Engineers\' Day',
      '🏑 National Sports Day',
      '🎖️ Armed Forces Flag Day'
    ]
  };

  List<String> getAvailableTemplates() {
    switch (greetingType) {
      case 'Anniversary':
        return anniversaryTemplates;
      case 'Festival':
        final religion = clientReligion ?? 'All';
        return [
          ...(festivalTemplatesByReligion['All'] ?? []),
          ...(festivalTemplatesByReligion[religion] ?? [])
        ];
      default:
        return birthdayTemplates;
    }
  }

  Future<void> autoScheduleGreetingsFunnel() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) return;

    final response = await Supabase.instance.client.rpc('schedule_auto_greetings_funnel', params: {
      'p_agent_id': agentId
    });

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Funnel Error: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Funnel prepared for automated greetings!')),
      );
    }
  }

  Future<void> triggerGreetingAutomation() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (startDate == null || endDate == null || selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please fill all fields")),
      );
      return;
    }
    final formattedRange =
        "${startDate!.toIso8601String().substring(0, 10)} to ${endDate!.toIso8601String().substring(0, 10)}";

    final response = await Supabase.instance.client.rpc('auto_send_greetings', params: {
      'p_agent_id': agentId,
      'p_type': greetingType.toLowerCase(),
      'p_date_range': formattedRange,
      'p_greetings_sent': 5,
      'p_credit_per_greeting': 2,
    });

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Greetings sent and credits deducted!')),
      );
    }
  }


  void handleAutoSend(BuildContext context) async {
    bool isActive = await checkSubscriptionStatus();

    if (!isActive) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Subscription Required"),
          content: const Text("To use automatic greetings and marketing tools, please subscribe."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
              child: const Text("View Plans"),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ PROCEED WITH AUTOMATION IF SUBSCRIBED
    runAutoSendFunction(); // Replace with your real function
  }

  @override
  Widget build(BuildContext context) {
    final availableTemplates = getAvailableTemplates();

    return Scaffold(
      appBar: AppBar(title: const Text("🎉 Greetings Automation")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Auto-Send Greeting Messages",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: greetingType,
            decoration: const InputDecoration(labelText: "Occasion"),
            items: const [
              DropdownMenuItem(value: "Birthday", child: Text("Birthday")),
              DropdownMenuItem(value: "Anniversary", child: Text("Anniversary")),
              DropdownMenuItem(value: "Festival", child: Text("Festival")),
            ],
            onChanged: (val) => setState(() {
              greetingType = val ?? 'Birthday';
              selectedTemplate = null;
            }),
          ),
          const SizedBox(height: 16),

          if (greetingType == 'Festival')
            DropdownButtonFormField<String>(
              value: clientReligion,
              decoration: const InputDecoration(labelText: "Filter by Religion"),
              items: religionOptions.map((religion) =>
                  DropdownMenuItem(value: religion, child: Text(religion))).toList(),
              onChanged: (val) => setState(() => clientReligion = val),
            ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Date Range",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: Text(startDate == null
                          ? 'Start Date'
                          : '📅 ${startDate!.toLocal().toIso8601String().substring(0, 10)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                      child: Text(endDate == null
                          ? 'End Date'
                          : '📅 ${endDate!.toLocal().toIso8601String().substring(0, 10)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedTemplate,
            hint: const Text("Select Template"),
            items: availableTemplates.map((template) =>
                DropdownMenuItem(value: template, child: Text(template))).toList(),
            onChanged: (val) => setState(() => selectedTemplate = val),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text("Enable Auto-Send on Occasion Day"),
            value: true,
            onChanged: (val) {},
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: triggerGreetingAutomation,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Send Greetings Now"),
          ),

          ElevatedButton.icon(
            onPressed: () {
              sendAutoGreetingWithCredit(
                type: "birthday",
                templateId: "T001",
                creditCost: 3,
              );
            },
            icon: const Icon(Icons.send),
            label: const Text("Send Auto Greetings"),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: autoScheduleGreetingsFunnel,
            icon: const Icon(Icons.schedule_send),
            label: const Text("Auto Funnel Setup"),
          )
        ],
      ),
    );
  }
}
