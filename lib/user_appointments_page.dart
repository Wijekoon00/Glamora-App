import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'models/review_model.dart';
import 'services/appointment_repo.dart';
import 'services/review_repo.dart';

class UserAppointmentsPage extends StatefulWidget {
  const UserAppointmentsPage({super.key});

  @override
  State<UserAppointmentsPage> createState() =>
      _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends State<UserAppointmentsPage> {
  final appointmentRepo = AppointmentRepo();
  final reviewRepo = ReviewRepo();

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

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

  // ⭐ REVIEW DIALOG
  Future<void> _openReviewDialog(AppointmentModel a) async {
    double rating = 5;
    final commentCtrl = TextEditingController();

    final alreadyReviewed =
        await reviewRepo.hasReviewedAppointment(a.id);

    if (alreadyReviewed) {
      _toast("You already reviewed this appointment");
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _card,
            title: const Text(
              "Rate Service",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.serviceName,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),

                // ⭐ STARS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          rating = star.toDouble();
                        });
                      },
                      icon: Icon(
                        star <= rating
                            ? Icons.star
                            : Icons.star_border,
                        color: _gold,
                        size: 32,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // COMMENT
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write your feedback",
                    hintStyle:
                        const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final user =
                      FirebaseAuth.instance.currentUser;

                  if (user == null) return;

                  final review = ReviewModel(
                    id: '',
                    userId: user.uid,
                    userName: a.userName,
                    appointmentId: a.id,
                    serviceId: a.serviceId,
                    serviceName: a.serviceName,
                    rating: rating,
                    comment: commentCtrl.text.trim(),
                  );

                  await reviewRepo.addReview(review);

                  if (!mounted) return;
                  Navigator.pop(context);
                  _toast("Review submitted ⭐");
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  // 📦 CARD UI
  Widget _buildCard(AppointmentModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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

            // STATUS CHIP
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    _statusColor(a.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _statusColor(a.status)),
              ),
              child: Text(
                a.status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor(a.status),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // ❌ CANCEL
            if (a.status == 'pending') ...[
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await appointmentRepo
                      .cancelAppointment(a.id);
                  _toast("Cancelled ❌");
                },
                child: const Text("Cancel Appointment"),
              ),
            ],

            // ⭐ RATE
            if (a.status == 'completed') ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _openReviewDialog(a),
                icon: const Icon(Icons.star),
                label: const Text("Rate Service"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "User not found",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      color: _bg,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: appointmentRepo
            .getUserAppointments(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final all = snapshot.data!;

          final upcoming = all
              .where((a) =>
                  a.status == 'pending' ||
                  a.status == 'approved')
              .toList();

          final history = all
              .where((a) =>
                  a.status == 'completed' ||
                  a.status == 'cancelled')
              .toList();

          if (all.isEmpty) {
            return const Center(
              child: Text(
                "No appointments yet",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionTitle("Upcoming Appointments"),
                ...upcoming.map(_buildCard),
              ],
              if (history.isNotEmpty) ...[
                _sectionTitle("History"),
                ...history.map(_buildCard),
              ],
            ],
          );
        },
      ),
    );
  }
}