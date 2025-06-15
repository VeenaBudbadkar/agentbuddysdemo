import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceLogRepository {
  final supabase = Supabase.instance.client;

  /// Insert a new service log
  Future<void> insertLog({
    required String agentId,
    required String clientId,
    required String serviceType,
    String? serviceDetail,
    String? deliveryChannel,
    String status = 'completed',
  }) async {
    final response = await supabase.from('service_logs').insert({
      'agent_id': agentId,
      'client_id': clientId,
      'service_type': serviceType,
      'service_detail': serviceDetail,
      'delivery_channel': deliveryChannel,
      'status': status,
      'date': DateTime.now().toUtc().toIso8601String(),
    });

    if (response.error != null) {
      throw Exception('❌ Failed to insert log: ${response.error!.message}');
    } else {
      print('✅ Service log inserted successfully!');
    }
  }

  /// Fetch all logs for a specific client
  Future<List<Map<String, dynamic>>> fetchLogsByClient(String clientId) async {
    final response = await supabase
        .from('service_logs')
        .select()
        .eq('client_id', clientId)
        .order('date', ascending: false);

    if (response.error != null) {
      throw Exception('❌ Failed to fetch logs: ${response.error!.message}');
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Fetch all logs for a specific agent
  Future<List<Map<String, dynamic>>> fetchLogsByAgent(String agentId) async {
    final response = await supabase
        .from('service_logs')
        .select()
        .eq('agent_id', agentId)
        .order('date', ascending: false);

    if (response.error != null) {
      throw Exception('❌ Failed to fetch logs: ${response.error!.message}');
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get count of services by type for a client (grouped in Dart)
  Future<Map<String, int>> getServiceCountByType(String clientId) async {
    final response = await supabase
        .from('service_logs')
        .select('service_type')
        .eq('client_id', clientId);

    if (response.error != null) {
      throw Exception('❌ Failed to fetch logs: ${response.error!.message}');
    }

    final logs = List<Map<String, dynamic>>.from(response.data);

    final Map<String, int> counts = {};
    for (var log in logs) {
      final type = log['service_type'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return counts;
  }
}
