import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';

class BeauticianCompletedPage extends StatelessWidget {
  const BeauticianCompletedPage({super.key});

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final repo = AppointmentRepo();

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
                "Error loading completed appointments",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final appointments = (snapshot.data ?? [])
              .where((a) => a.status == 'completed')
              .toList();

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                "No completed appointments",
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
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
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}