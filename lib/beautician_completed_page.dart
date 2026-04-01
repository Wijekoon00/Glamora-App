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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!
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
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: ListTile(
                  title: Text(
                    a.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    "${a.userName} • ${DateFormat('yyyy-MM-dd').format(a.date)} • ${a.timeSlot}",
                    style: const TextStyle(color: Colors.white70),
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