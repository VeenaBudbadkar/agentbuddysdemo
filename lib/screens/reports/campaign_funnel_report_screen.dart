import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';



class CampaignFunnelReportScreen extends StatefulWidget {
  final String campaignName;

  const CampaignFunnelReportScreen({
    super.key,
    required this.campaignName,
  });

  @override
  State<CampaignFunnelReportScreen> createState() => _CampaignFunnelReportScreenState();
}

class _CampaignFunnelReportScreenState extends State<CampaignFunnelReportScreen> {
  int totalCalls = 0;
  int interested = 0;
  int notInterested = 0;
  int sales = 0;

  late final RealtimeChannel channel;

  @override
  void initState() {
    super.initState();
    fetchFunnelData();
    subscribeToChanges();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  Future<void> fetchFunnelData() async {
    final supabase = Supabase.instance.client;

    final res = await supabase
        .from('campaign_call_logs')
        .select('outcome')
        .eq('campaign_name', widget.campaignName);

    totalCalls = res.length;
    interested = res.where((row) => row['outcome'] == 'Interested').length;
    notInterested = res.where((row) => row['outcome'] == 'Not Interested').length;
    sales = res.where((row) => row['outcome'] == 'Sale' || row['outcome'] == 'Converted').length;

    if (mounted) {
      setState(() {});
    }
  }

  void subscribeToChanges() {
    final supabase = Supabase.instance.client;

    channel = supabase.channel('campaign_funnel_${widget.campaignName}')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'campaign_call_logs',
          filter: 'campaign_name=eq.${widget.campaignName}',
        ),
            (payload, [ref]) {
          debugPrint("📡 Realtime Insert: $payload");

          final newOutcome = payload['new']['outcome'] as String?;

          totalCalls += 1;
          if (newOutcome == 'Interested') interested += 1;
          if (newOutcome == 'Not Interested') notInterested += 1;
          if (newOutcome == 'Sale' || newOutcome == 'Converted') sales += 1;

          if (mounted) setState(() {});
        },
      )
      ..subscribe();
  }
  Future<void> _generateAndSharePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("AgentBuddys Campaign Funnel Report",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text("Campaign: ${widget.campaignName}"),
              pw.Text("Total Calls: $totalCalls"),
              pw.Text("Interested: $interested"),
              pw.Text("Not Interested: $notInterested"),
              pw.Text("Sales: $sales"),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/funnel_report.pdf");
    await file.writeAsBytes(await pdf.save());

    debugPrint("✅ PDF saved at: ${file.path}");

    // 👉 Open share dialog
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'funnel_report.pdf');
  }
  Future<void> openWhatsAppWithMessage() async {
    final message = Uri.encodeComponent("Hey! Here’s my Campaign Funnel Report. 📈🚀");
    final url = "https://wa.me/?text=$message";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint("WhatsApp not installed!");
    }
  }


  Future<void> _generatePDFAndShareToWhatsApp() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("AgentBuddys Campaign Funnel Report",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text("Campaign: ${widget.campaignName}"),
              pw.Text("Total Calls: $totalCalls"),
              pw.Text("Interested: $interested"),
              pw.Text("Not Interested: $notInterested"),
              pw.Text("Sales: $sales"),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/funnel_report.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    debugPrint("✅ PDF saved at: $filePath");

    final message = "📈 Here’s my AgentBuddys Campaign Funnel Report for ${widget.campaignName}.\n"
        "Total Calls: $totalCalls\n"
        "Interested: $interested\n"
        "Sales: $sales 🚀\n"
        "Let's discuss!";

    await Share.shareXFiles(
      [XFile(filePath)],
      text: message,
      subject: "AgentBuddys Funnel Report",
    );
  }



  @override
  Widget build(BuildContext context) {
    final dataMap = {
      "Interested": interested.toDouble(),
      "Not Interested": notInterested.toDouble(),
      "Sales": sales.toDouble(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text("Campaign Funnel: ${widget.campaignName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "📈 Funnel Summary (Live!)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Total Calls: $totalCalls", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartRadius: MediaQuery.of(context).size.width / 2.2,
              chartType: ChartType.ring,
              ringStrokeWidth: 32,
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
              ),

              chartValuesOptions: const ChartValuesOptions(
                showChartValues: true,
                showChartValuesInPercentage: true,
              ),
            ),
            const SizedBox(height: 20),
            Text("Interested: $interested"),
            Text("Not Interested: $notInterested"),
            Text("Sales: $sales"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back"),

            ),
            ElevatedButton.icon(
              onPressed: _generateAndSharePDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Export & Share PDF"),
            ),
            ElevatedButton.icon(
              onPressed: _generatePDFAndShareToWhatsApp,
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              label: const Text("Share to WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),


          ],
        ),
      ),
    );
  }
}
