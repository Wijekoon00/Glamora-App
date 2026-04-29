import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianCompletedPage extends StatelessWidget {
  const BeauticianCompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppointmentRepo();

    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: repo.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: LuxuryTheme.purpleLight),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: LuxuryTheme.purpleLight.withAlpha(120),
                      size: 48),
                  const SizedBox(height: 12),
                  const Text('Error loading appointments',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          final appointments = (snapshot.data ?? [])
              .where((a) => a.status == 'completed')
              .toList();

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryTheme.purple.withAlpha(30),
                      border: Border.all(
                          color: LuxuryTheme.purple.withAlpha(60)),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: LuxuryTheme.purpleLight, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No completed jobs yet',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Completed appointments will appear here',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _CompletedCard(appointment: appointments[index]),
          );
        },
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.appointment});
  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.serviceName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Customer: ${a.userName}',
                    style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 12)),
              ],
            )),
            // Completed badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.blue.withAlpha(100)),
              ),
              child: const Text('COMPLETED',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 14),
          // Divider
          Divider(color: LuxuryTheme.purple.withAlpha(40)),
          const SizedBox(height: 10),
          // Details grid
          Row(children: [
            Expanded(child: _detail(Icons.calendar_today_outlined,
                DateFormat('MMM dd, yyyy').format(a.date))),
            Expanded(child: _detail(Icons.access_time_rounded,
                a.timeSlot)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _detail(Icons.payments_outlined,
                '${a.price} LKR')),
            Expanded(child: _detail(Icons.timer_outlined,
                '${a.duration} mins')),
          ]),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: LuxuryTheme.purpleLight.withAlpha(160), size: 14),
      const SizedBox(width: 6),
      Text(text,
          style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 12)),
    ]);
  }
}
