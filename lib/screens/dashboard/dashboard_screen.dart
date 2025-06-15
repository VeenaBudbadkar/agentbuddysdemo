import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Assuming these are correct paths and the widgets are defined there
import 'profile_header.dart';
import '../leads/lead_form_screen.dart';
import '../leads/lead_list_screen.dart';
import '../voice_assistant_screen.dart';
import '../monetization/credit_store_screen.dart'; // Not directly used in this snippet
import '../subscription/subscription_screen.dart'; // Not directly used in this snippet
import '../greetings/birthday_greeting_screen.dart';
import '../calendar/calendar_view_screen.dart';
import 'package:agentbuddys/activity/call_list_screen.dart';
import 'package:agentbuddys/activity/meeting_list_screen.dart';
// Assuming dashboard_kpi_section.dart provides KPIDashboardCarousel
import 'dashboard_kpi_section.dart';
import 'filtered_client_list_screen.dart';
// Assuming training_suggestions_ui.dart provides SuggestedTrainingCarousel (though not used in final layout)
 import 'package:agentbuddys/screens/dashboard/training_suggestions_ui.dart';
// Assuming top_agents_rank_ui.dart provides TopAgentsRankUi
import 'top_agents_rank_ui.dart';
import '../../auth_gate.dart'; // Not directly used in this snippet
import '../settings/agent_profile_settings_screen.dart'; // Not directly used in this snippet
// Assuming trigger_carousel_ui.dart provides TriggerCarousel
import 'trigger_carousel_ui.dart';
// Duplicate import of training_suggestions_ui.dart - ensure one is correct if used
//import 'training_suggestions_ui.dart';
import 'package:agentbuddys/screens/training/training_hub_screen.dart';
import 'dart:async';
import 'main_navigation.dart';
import '../../components/premium_services_section.dart';
import 'package:agentbuddys/screens/campaigns/campaign_list_screen.dart';









// --- Placeholder Widgets (IF NOT PROVIDED BY IMPORTS) ---
// If TriggerCarousel, KPIDashboardCarousel, TopAgentsRankUi are not in the imported files,
// define them here or ensure correct imports. For example:

// class TriggerCarousel extends StatelessWidget {
//   const TriggerCarousel({super.key});
//   @override
//   Widget build(BuildContext context) => const Card(child: Center(child: Text("Trigger Carousel")));
// }

// class KPIDashboardCarousel extends StatelessWidget {
//   const KPIDashboardCarousel({super.key});
//   @override
//   Widget build(BuildContext context) => const Card(child: Center(child: Text("KPI Carousel")));
// }

// class TopAgentsRankUi extends StatelessWidget {
//   const TopAgentsRankUi({super.key});
//   @override
//   Widget build(BuildContext context) => const Card(child: Center(child: Text("Top Agents UI")));
// }
// --- End Placeholder Widgets ---


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ✅ Add to your DashboardScreenState:


  int firstCallCount = 0;
  int followupCallCount = 0;
  int firstMeetCount = 0;
  int followupMeetCount = 0;
  bool _isLoadingCounts = false;

  String selectedPeriod = 'This Month'; // Consider making this interactive
  String selectedMonthYear = "${DateTime
      .now()
      .year}-${DateTime
      .now()
      .month
      .toString()
      .padLeft(2, '0')}"; // Default to current month

  // _kpi data will be fetched by FutureBuilder, so no need for a state variable here
  // Map<String, dynamic> _kpi = {'leads': 0, 'appointments': 0, 'policies': 0, 'premium': 0.0};
  Map<String, int> _leadCounts = {'Hot': 0, 'Warm': 0, 'Cold': 0};


    @override
    void initState() {
      super.initState();
      // These fetch data that updates specific parts of the UI not covered by the main FutureBuilder
      fetchLeadCounts();
      fetchAppointmentCounts();
      // loadAgentData(); // This is redundant if fetchAgentProfile in FutureBuilder is used
      // fetchKPIData(); // This will be called by FutureBuilder
    }


  Future<void> fetchAppointmentCounts() async {
    if (!mounted) return;
    setState(() => _isLoadingCounts = true);
    try {
      final agentId = Supabase.instance.client.auth.currentUser?.id;
      if (agentId == null) throw Exception("No Agent ID for appointment counts");

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from('call_meeting_logs')
          .select('log_type, interaction_level')
          .eq('agent_id', agentId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (!mounted) return;
      setState(() {
        firstCallCount = response.where((e) => e['log_type'] == 'Call' && e['interaction_level'] == '1st Appointment').length;
        followupCallCount = response.where((e) => e['log_type'] == 'Call' && e['interaction_level'] == 'Follow-up').length;
        firstMeetCount = response.where((e) => e['log_type'] == 'Meeting' && e['interaction_level'] == '1st Appointment').length;
        followupMeetCount = response.where((e) => e['log_type'] == 'Meeting' && e['interaction_level'] == 'Follow-up').length;
        _isLoadingCounts = false;
      });
    } catch (e) {
      debugPrint("Error fetching appointment counts: $e");
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  Future<Map<String, dynamic>> fetchAgentProfile() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) {
      debugPrint("Agent not logged in for profile fetch.");
      // Return an empty map or throw an error to be caught by FutureBuilder
      return Future.error("Agent not logged in");
    }
    try {
      final data = await Supabase.instance.client
          .from('agent_profile')
          .select('name, photo_url, credit_balance, membership_plan, monthly_rank')
          .eq('agent_id', agentId) // Assuming your column is 'agent_id' not 'user_id' as in the top-level func
          .single();
      return data; // Supabase single() throws if not exactly one row, or returns data.
    } catch (e) {
      debugPrint("Error fetching agent profile: $e");
      // If no profile found, Supabase might throw PostgrestException (code PGRST116)
      // Or it might return null if .maybeSingle() was used and nothing found.
      // Here, .single() is used, so an error is expected if not found.
      if (e is PostgrestException && e.code == 'PGRST116') {
        return Future.error("No agent profile found.");
      }
      return Future.error("Failed to load profile: $e");
    }
  }

  Future<void> loadAgentData() async { // This seems redundant given fetchAgentProfile
    try {
      final agentId = Supabase.instance.client.auth.currentUser?.id;
      if (agentId == null) {
        debugPrint("Agent not logged in (loadAgentData).");
        return;
      }
      // This selects all columns, fetchAgentProfile is more specific
      final response = await Supabase.instance.client
          .from('agent_profile')
          .select()
          .eq('agent_id', agentId)
          .maybeSingle();

      if (response != null) {
        debugPrint("Agent Name (from loadAgentData): ${response['name']}");
        // If you need to use this data, setState here with relevant state variables.
      } else {
        debugPrint("No agent data found (loadAgentData).");
      }
    } catch (e) {
      debugPrint("Error loading agent data: $e");
    }
  }

  Future<int> fetchClientCount() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) {
      debugPrint("Agent not logged in for client count.");
      return 0; // Or throw error
    }
    try {
      // Using count option for efficiency if only count is needed
      final response = await Supabase.instance.client
          .from('client_master')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('agent_id', agentId);
      return response.count ?? 0;
    } catch (e) {
      debugPrint("Error fetching client count: $e");
      return 0; // Or throw error
    }
  }

  Future<Map<String, dynamic>> fetchKPIData() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) {
      debugPrint("Agent not logged in for KPI data.");
      return Future.error("Agent not logged in");
    }

    List<String> monthsToFetch = [];
    final year = selectedMonthYear.split('-')[0];
    final month = int.parse(selectedMonthYear.split('-')[1]);

    // This logic for period selection needs to be robust, especially around year boundaries
    if (selectedPeriod == 'This Month') {
      monthsToFetch = [selectedMonthYear];
    } else if (selectedPeriod == 'Last Quarter') {
      // Simplified example, refine for correctness
      final currentMonthDate = DateTime(int.parse(year), month);
      List<DateTime> quarterMonths = [];
      for (int i = 0; i < 3; i++) {
        quarterMonths.add(DateTime(currentMonthDate.year, currentMonthDate.month - ((currentMonthDate.month -1) % 3) - i));
      }
      monthsToFetch = quarterMonths.map((d) => "${d.year}-${d.month.toString().padLeft(2, '0')}").toList().reversed.toList();

    } else if (selectedPeriod == 'Last 6 Months') {
      monthsToFetch = List.generate(6, (i) {
        final d = DateTime(int.parse(year), month - i);
        return '${d.year}-${d.month.toString().padLeft(2, '0')}';
      }).reversed.toList();
    } else if (selectedPeriod == 'Last Year') {
      monthsToFetch = List.generate(12, (i) => '${int.parse(year) - 1}-${(i + 1).toString().padLeft(2, '0')}');
    }

    if (monthsToFetch.isEmpty) monthsToFetch.add(selectedMonthYear); // Fallback

    try {
      final data = await Supabase.instance.client
          .from('kpis')
          .select()
          .eq('agent_id', agentId)
          .in_('month_year', monthsToFetch);

      int leads = 0, appointments = 0, policies = 0;
      double premium = 0.0;

      for (var row in data) {
        leads += (row['leads_added'] as num?)?.toInt() ?? 0;
        appointments += (row['appointments'] as num?)?.toInt() ?? 0;
        policies += (row['policies_closed'] as num?)?.toInt() ?? 0;
        premium += (row['premium_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return {'leads': leads, 'appointments': appointments, 'policies': policies, 'premium': premium};
    } catch (e) {
      debugPrint("Error fetching KPI data: $e");
      return Future.error("Failed to load KPIs: $e");
    }
  }

  Future<void> fetchLeadCounts() async {
    if (!mounted) return;
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    if (agentId == null) {
      debugPrint("Agent not logged in for lead counts.");
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('lead_master')
          .select('status')
          .eq('agent_id', agentId);

      int hot = 0, warm = 0, cold = 0;
      for (var row in data) {
        switch (row['status']?.toString()) {
          case 'Hot': hot++; break;
          case 'Warm': warm++; break;
          case 'Cold': cold++; break;
        }
      }
      if (!mounted) return;
      setState(() {
        _leadCounts = {'Hot': hot, 'Warm': warm, 'Cold': cold};
      });
    } catch (e) {
      debugPrint("Error fetching lead counts: $e");
    }
  }

  // _buildProfileHeader is not needed if ProfileHeader widget is used directly
  // Widget _buildProfileHeader() { ... }

  Widget _buildTodoList() { // This is _buildTodaySection, which is already defined.
    return _buildTodaySection();
  }

  // _buildCallMeetingButtons is defined but not used in the main layout.
  // Widget _buildCallMeetingButtons() { ... }

  // _buildRankList is defined but not used in the main layout.
  // Widget _buildRankList() { ... }

  Widget _buildTodaySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's To-Do 📌",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoadingCounts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CallListScreen()),
                      ),
                      child: _StatusCard(
                        title: "Calls",
                        subtitle: "$firstCallCount 1st\n$followupCallCount Follow-up",
                        icon: Icons.phone,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MeetingListScreen()),
                      ),
                      child: _StatusCard(
                        title: "Meetings",
                        subtitle: "$firstMeetCount 1st\n$followupMeetCount Follow-up",
                        icon: Icons.group_work,
                        color: Colors.greenAccent.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BirthdayGreetingScreen()),
                    ),
                    icon: const Icon(Icons.cake_outlined),
                    label: const Text("Birthdays Today"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CampaignListScreen()),
                      );
                    },
                    icon: const Icon(Icons.wifi_calling_3_sharp),
                    label: const Text("Start Campaign"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddClientButton() {
    return SizedBox( // Give it a specific width or use Expanded in a Row
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeadFormScreen())),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text("Add Leads+", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLeadTypeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem("Hot 🔥", Colors.red.shade400, _leadCounts['Hot'] ?? 0),
            _buildStatusItem("Warm 🌤️", Colors.orange.shade400, _leadCounts['Warm'] ?? 0),
            _buildStatusItem("Cold ❄️", Colors.blue.shade300, _leadCounts['Cold'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, Color color, int count) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadListScreen(filterStatus: label.split(" ")[0]))), // Use "Hot" not "Hot 🔥"
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 18,
              child: Text(
                count.toString(),
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildAskBuddySection() {
    return Card(
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell( // Use InkWell for tap effect
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceAssistantScreen())),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListTile(
            leading: Icon(Icons.mic_none_outlined, color: Colors.deepPurple, size: 30),
            title: const Text("Ask Buddy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            subtitle: const Text("Your AI Voice Assistant", style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }


  // This is the _buildTriggerCarousel from the file content, assuming TriggerCarousel widget might be different
  // If TriggerCarousel UI is what this method builds, then you can rename this or use the TriggerCarousel widget directly.

  // THIS IS THE PRIMARY METHOD TO BUILD THE DASHBOARD'S BODY CONTENT
  Widget _buildDashboardScreenContent(Map<String, dynamic> profile, int clientCount, Map<String, dynamic> kpi) {
    return RefreshIndicator(
      onRefresh: () async {
        // Re-fetch all necessary data
        // Calling setState in .then() for futures that update the main builder's data
        // For fetchLeadCounts and fetchAppointmentCounts, their own setState will handle UI updates.
        await Future.wait([
          fetchAgentProfile().then((_) => {if (mounted) setState(() {})}),
          fetchClientCount().then((_) => {if (mounted) setState(() {})}),
          fetchKPIData().then((_) => {if (mounted) setState(() {})}),
          fetchLeadCounts(),
          fetchAppointmentCounts(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width where appropriate
          children: [
            ProfileHeader(
              agentName: profile['name']?.toString() ?? 'Agent',
              photoUrl: profile['photo_url']?.toString() ?? '',
              clientCount: clientCount,
              creditBalance: (profile['credit_balance'] as num?)?.toInt() ?? 0,
              monthlyRank: (profile['monthly_rank'] as num?)?.toInt() ?? 0,
              membershipPlan: profile['membership_plan']?.toString() ?? 'Free',
            ),
            _buildTodaySection(), // This was previously _buildTodoList
            // If TriggerCarousel is an imported widget:
             // Ensure this is defined or imported
            // Or if you want to use the local _buildInternalTriggerCarouselUi:

            const TriggerCarousel(),
            const SizedBox(height: 8),


// 👉 Insert Premium Services here (before KPI)
            PremiumServicesSection(),

            const SizedBox(height: 8),
            const KPIDashboardCarousel(), // KPI comes after Premium Services

            _buildLeadTypeCard(),
            const SizedBox(height: 16),
            _buildAddClientButton(),
            const SizedBox(height: 8),
            _buildAskBuddySection(),
            const SizedBox(height: 8),
            const SuggestedTrainingCarousel(),

            // SuggestedTrainingCarousel(), // This was imported but not used in the layout
            const TopAgentsRankUi(), // Ensure this is defined or imported
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            fetchAgentProfile(),
            fetchClientCount(),
            fetchKPIData(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.hasError) {
              debugPrint("❌ FutureBuilder Error: ${snapshot.error}\n${snapshot.stackTrace}");
              // Provide more user-friendly error messages
              String errorMessage = "Error loading dashboard.";
              if (snapshot.error.toString().contains("No agent profile found")) {
                errorMessage = "Profile not found. Please complete your registration or contact support.";
              } else if (snapshot.error.toString().contains("Agent not logged in")){
                errorMessage = "You are not logged in. Please log in to continue.";
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              // This will re-trigger the FutureBuilder
                            });
                          }
                        },
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint("🔄 Loading main dashboard data...");
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.length < 3) {
              debugPrint("❌ Snapshot has no data or data is incomplete.");
              return const Center(child: Text("No data available. Please try again later."));
            }

            final profileData = snapshot.data![0] as Map<String, dynamic>? ?? {};
            final clientCount = snapshot.data![1] as int? ?? 0;
            final kpiData = snapshot.data![2] as Map<String, dynamic>? ?? {};

            debugPrint("✅ Dashboard FutureBuilder received data.");
            // Use the corrected method name for building the dashboard content
            return _buildDashboardScreenContent(profileData, clientCount, kpiData);
          },
        ),
      ),
    );
  }
}

// _AgentRankCard - defined but not used in the final layout in _buildDashboardScreenContent
class _AgentRankCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String branch;
  final String company;
  final String location;
  final String metric;
  final String value;

  const _AgentRankCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.branch,
    required this.company,
    required this.location,
    required this.metric,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("($branch) $company, $location", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text("$metric: $value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container( // Changed from Card to Container for more flexible styling if needed
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important for column height in a Row
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SuggestedTrainingCarousel extends StatefulWidget {
  const SuggestedTrainingCarousel({super.key});

  @override
  State<SuggestedTrainingCarousel> createState() => _SuggestedTrainingCarouselState();
}

class _SuggestedTrainingCarouselState extends State<SuggestedTrainingCarousel> {
  final List<Map<String, String>> trainingCards = [
    {
      'title': 'IC 38 Made Easy',
      'tag': 'Starter',
      'image': 'https://via.placeholder.com/300x200.png?text=IC+38',
      'location': 'Mumbai'
    },
    {
      'title': 'Plan 914 Deep Dive',
      'tag': 'Plans',
      'image': 'https://via.placeholder.com/300x200.png?text=Plan+914',
      'location': 'Delhi'
    },
    {
      'title': 'Mission MDRT',
      'tag': 'Advanced',
      'image': 'https://via.placeholder.com/300x200.png?text=MDRT',
      'location': 'Mumbai'
    },
  ];

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  String agentLocation = 'Mumbai'; // This should be dynamically set from agent profile

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_scrollController.hasClients) {
        _currentIndex = (_currentIndex + 1) % filteredTrainingCards.length;
        _scrollController.animateTo(
          _currentIndex * 228.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Map<String, String>> get filteredTrainingCards => trainingCards
      .where((card) => card['location'] == agentLocation)
      .toList();

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0, left: 4),
            child: Text(
              "🎓 Suggested Training",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: filteredTrainingCards.length,
              itemBuilder: (context, index) {
                final card = filteredTrainingCards[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingHubScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: card['title']!,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: Image.network(
                              card['image']!,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 90,
                                color: Colors.grey.shade300,
                                child: const Center(child: Icon(Icons.broken_image, size: 40)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card['title']!,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  card['tag']!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildBottomNavigationBar() {
  return BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 6.0,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
    ),
  );
}




// REMOVED the top-level functions `_fetchAgentProfile`, `_fetchClientCount`, `_fetchKPIData`
// and `buildDashboardBuilder` as their logic has been integrated into the `_DashboardScreenState` class.

// REMOVED the duplicate `_buildDashboardContent` and stray Text widgets at the end of the file.