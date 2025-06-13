// 📁 File: calendar_view_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final agentId = Supabase.instance.client.auth.currentUser?.id;
    final response = await Supabase.instance.client
        .from('call_meeting_logs')
        .select()
        .eq('agent_id', agentId)
        .not('next_action_date', 'is', null);

    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var item in response) {
      final date = DateTime.parse(item['next_action_date']).toLocal();
      final cleanDate = DateTime(date.year, date.month, date.day);
      if (!events.containsKey(cleanDate)) {
        events[cleanDate] = [];
      }
      events[cleanDate]!.add(item);
    }

    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onEditEvent(Map<String, dynamic> event) async {
    TextEditingController notesController = TextEditingController(text: event['followup_reason'] ?? '');
    DateTime selectedDate = DateTime.parse(event['next_action_date']).toLocal();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(labelText: "Reason / Note"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final newDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (newDate != null) selectedDate = newDate;
              },
              child: const Text("Change Date"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('call_meeting_logs')
                  .update({
                'followup_reason': notesController.text,
                'next_action_date': selectedDate.toIso8601String(),
              })
                  .eq('id', event['id']);
              Navigator.pop(context);
              _fetchEvents();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar View"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_month),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                return ListTile(
                  title: Text("${event['log_type']} - ${event['interaction_level'] ?? ''}"),
                  subtitle: Text("${event['followup_reason'] ?? ''}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _onEditEvent(event),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
