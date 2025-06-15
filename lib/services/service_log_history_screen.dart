import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/service_log_repository.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/service_log_pdf_helper.dart';


class ServiceLogHistoryScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ServiceLogHistoryScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  State<ServiceLogHistoryScreen> createState() => _ServiceLogHistoryScreenState();
}

class _ServiceLogHistoryScreenState extends State<ServiceLogHistoryScreen> {
  final ServiceLogRepository _repo = ServiceLogRepository();
  late Future<List<Map<String, dynamic>>> _logsFuture;
  late Future<Map<String, int>> _countFuture;

  // Filter state
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _logsFuture = _repo.fetchLogsByClient(widget.clientId);
    _countFuture = _repo.getServiceCountByType(widget.clientId);
  }

  String _formatDate(String isoString) {
    final dateTime = DateTime.tryParse(isoString);
    if (dateTime != null) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    }
    return isoString;
  }

  bool _isInSelectedMonth(String isoString) {
    final dateTime = DateTime.tryParse(isoString);
    if (dateTime == null) return false;
    return dateTime.month == _selectedMonth.month && dateTime.year == _selectedMonth.year;
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.clientName}'s Service History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Generating PDF...")),
                  );

                  final logs = await _logsFuture;
                  final filtered = logs.where((log) =>
                      _isInSelectedMonth(log['date'])).toList();

                  if (filtered.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("No logs to export for this month.")),
                    );
                    return;
                  }

                  // 1️⃣ Generate PDF bytes
                  final pdfData = await ServiceLogPdfHelper.generatePdf(
                    clientName: widget.clientName,
                    logs: filtered,
                    month: DateFormat('MMMM yyyy').format(_selectedMonth),
                  );

                  // 2️⃣ Open share preview
                  await Printing.layoutPdf(onLayout: (_) async => pdfData);

                  // 3️⃣ Also prepare WhatsApp message
                  final summary = filtered
                      .map((log) =>
                  "✅ ${log['service_type'].toString().replaceAll(
                      '_', ' ')} on ${_formatDate(log['date'])}")
                      .join('\n');

                  final message = Uri.encodeComponent(
                      "Hi ${widget
                          .clientName},\n\nHere’s your Service Log for ${DateFormat(
                          'MMMM yyyy').format(
                          _selectedMonth)}:\n\n$summary\n\n– Your Agent"
                  );

                  final whatsappUrl = "https://wa.me/?text=$message";

                  if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                    await launchUrl(Uri.parse(whatsappUrl),
                        mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not open WhatsApp")),
                    );
                  }
                },
              );
              // TODO: Hook to PDF/Share logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export & Share coming soon!")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing: $formattedMonth",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Change Month"),
                ),
              ],
            ),
          ),

          // Count Chips
          FutureBuilder<Map<String, int>>(
            future: _countFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              final counts = snapshot.data ?? {};
              if (counts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No services yet."),
                );
              }

              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: counts.entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        "${e.key.replaceAll('_', ' ')}: ${e.value}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Logs List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('❌ Error: ${snapshot.error}'));
                }

                final logs = snapshot.data ?? [];
                final filtered = logs.where((log) => _isInSelectedMonth(log['date'])).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No service logs for this month."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.blue),
                      title: Text(
                        log['service_type'].toString().replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(log['date'])),
                          if (log['service_detail'] != null && log['service_detail'].toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                log['service_detail'],
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        log['delivery_channel']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
