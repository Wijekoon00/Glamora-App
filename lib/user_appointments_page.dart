import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';

class UserAppointmentsPage extends StatefulWidget {
  const UserAppointmentsPage({super.key});

  @override
  State<UserAppointmentsPage> createState() => _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends State<UserAppointmentsPage> {
  final appointmentRepo = AppointmentRepo();

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "User not found",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      color: _bg,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: appointmentRepo.getUserAppointments(user.uid),
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
                "No appointments yet",
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
                      const SizedBox(height: 8),
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
                      if (a.status == 'pending') ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              await appointmentRepo.cancelAppointment(a.id);
                              _toast("Appointment cancelled");
                            } catch (e) {
                              _toast("Cancel failed: $e");
                            }
                          },
                          child: const Text("Cancel Appointment"),
                        ),
                      ]
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