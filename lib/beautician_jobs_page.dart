import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';

class BeauticianJobsPage extends StatefulWidget {
  const BeauticianJobsPage({super.key});

  @override
  State<BeauticianJobsPage> createState() => _BeauticianJobsPageState();
}

class _BeauticianJobsPageState extends State<BeauticianJobsPage> {
  final repo = AppointmentRepo();

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  bool _loading = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _card),
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
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await repo.updateStatus(id, status);

      if (status == 'approved') {
        _toast("Appointment approved ✅");
      } else if (status == 'cancelled') {
        _toast("Appointment cancelled ❌");
      } else if (status == 'completed') {
        _toast("Appointment completed ✅");
      } else {
        _toast("Updated successfully");
      }
    } catch (e) {
      _toast("Update failed");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildActionButtons(AppointmentModel a) {
    if (a.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  _loading ? null : () => _updateStatus(a.id, 'approved'),
              child: const Text("Approve"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  _loading ? null : () => _updateStatus(a.id, 'cancelled'),
              child: const Text("Cancel"),
            ),
          ),
        ],
      );
    }

    if (a.status == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
          ),
          onPressed:
              _loading ? null : () => _updateStatus(a.id, 'completed'),
          child: const Text("Mark Completed"),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: repo.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading appointments",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // 🔥 ONLY SHOW ACTIVE APPOINTMENTS
          final appointments = (snapshot.data ?? [])
              .where((a) => a.status == 'pending' || a.status == 'approved')
              .toList();

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                "No active appointments",
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