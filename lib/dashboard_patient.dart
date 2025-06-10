import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  String? _service;
  String? _doctorId;

  final List<String> _services = [
    'Consultation',
    'Checkup',
    'Follow-up',
  ];

  Future<void> _bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDay == null || _selectedTime == null || _service == null || _doctorId == null) {
      return;
    }
    final date = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    await FirebaseFirestore.instance.collection('appointments').add({
      'patientId': user.uid,
      'doctorId': _doctorId,
      'service': _service,
      'date': Timestamp.fromDate(date),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked')));
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Text('Welcome, ${user.email}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      return Card(
                        child: ListTile(
                          selected: _doctorId == d.id,
                          title: Text(d['name']),
                          subtitle: Text(d['specialization']),
                          onTap: () => setState(() => _doctorId = d.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            TextButton(
              onPressed: _pickTime,
              child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
            ),
            DropdownButton<String>(
              hint: const Text('Select Service'),
              value: _service,
              onChanged: (value) => setState(() => _service = value),
              items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: _bookAppointment,
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
