import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import '../services/appointment_repo.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  final repo = AppointmentRepo();

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _card,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await repo.updateStatus(id, status);
      _toast("Appointment updated ✅");
    } catch (e) {
      _toast("Update failed: $e");
    }
  }

  Widget _buildActionButtons(AppointmentModel a) {
    if (a.status == 'pending') {
      return Wrap(
        spacing: 8,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _updateStatus(a.id, 'approved'),
            child: const Text("Approve"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _updateStatus(a.id, 'cancelled'),
            child: const Text("Cancel"),
          ),
        ],
      );
    }

    if (a.status == 'approved') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
        ),
        onPressed: () => _updateStatus(a.id, 'completed'),
        child: const Text("Mark Completed"),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          "Appointments",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: repo.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                "No appointments found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = appointments[index];

              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Customer: ${a.userName}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Date: ${DateFormat('yyyy-MM-dd').format(a.date)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Time: ${a.timeSlot}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Price: ${a.price} LKR",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Duration: ${a.duration} mins",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(a.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(a.status)),
                        ),
                        child: Text(
                          a.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(a.status),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButtons(a),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}