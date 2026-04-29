import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'models/review_model.dart';
import 'services/appointment_repo.dart';
import 'services/review_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class UserAppointmentsPage extends StatefulWidget {
  const UserAppointmentsPage({super.key});

  @override
  State<UserAppointmentsPage> createState() =>
      _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends State<UserAppointmentsPage> {
  final appointmentRepo = AppointmentRepo();
  final reviewRepo = ReviewRepo();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: LuxuryTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LuxuryTheme.purple.withAlpha(80)),
        ),
      ),
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blueAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  // ── Review dialog ───────────────────────────────────────────────────────────
  Future<void> _openReviewDialog(AppointmentModel a) async {
    double rating = 5;
    final commentCtrl = TextEditingController();

    final alreadyReviewed =
        await reviewRepo.hasReviewedAppointment(a.id);

    if (alreadyReviewed) {
      _toast("You already reviewed this appointment");
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 28,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            decoration: BoxDecoration(
              color: LuxuryTheme.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(60), width: 1),
              boxShadow: [
                BoxShadow(
                  color: LuxuryTheme.purple.withAlpha(40),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.purple.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [LuxuryTheme.gold, LuxuryTheme.purpleLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Rate Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Service name
                Text(
                  a.serviceName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Stars
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => rating = star.toDouble()),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: LuxuryTheme.gold,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Comment field
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: LuxuryTheme.purpleLight,
                  decoration: InputDecoration(
                    hintText: "Write your feedback…",
                    hintStyle: TextStyle(
                        color: Colors.white.withAlpha(60), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF0A0A14),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: LuxuryTheme.purple.withAlpha(80), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: LuxuryTheme.purpleLight, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Submit – purple gradient
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
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
                          Navigator.pop(ctx);
                          _toast("Review submitted ⭐");
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [
                                LuxuryTheme.purple,
                                LuxuryTheme.purpleLight
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LuxuryTheme.purple.withAlpha(100),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Submit Review",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Appointment card ────────────────────────────────────────────────────────
  Widget _buildCard(AppointmentModel a) {
    final statusColor = _statusColor(a.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(30),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header: icon + service name ──────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LuxuryTheme.purpleDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: LuxuryTheme.purpleLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Detail grid (2 × 2) ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    Icons.calendar_today_rounded,
                    DateFormat('yyyy-MM-dd').format(a.date),
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.access_time_rounded,
                    a.timeSlot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    Icons.attach_money_rounded,
                    "${a.price} LKR",
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    Icons.timer_rounded,
                    "${a.duration} mins",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Status badge ──────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                a.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // ── Cancel button ─────────────────────────────────────────────
            if (a.status == 'pending') ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  await appointmentRepo.cancelAppointment(a.id);
                  _toast("Appointment cancelled");
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB71C1C),
                        Colors.redAccent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Cancel Appointment",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── Rate button ───────────────────────────────────────────────
            if (a.status == 'completed') ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _openReviewDialog(a),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [LuxuryTheme.gold, LuxuryTheme.goldLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LuxuryTheme.gold.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Rate Service",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Detail row item ─────────────────────────────────────────────────────────
  Widget _detailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: LuxuryTheme.purpleLight, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          // Purple accent bar
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: LuxuryTheme.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          // Count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: LuxuryTheme.purpleDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                color: LuxuryTheme.purpleLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxuryTheme.purpleDim,
              boxShadow: [
                BoxShadow(
                  color: LuxuryTheme.purple.withAlpha(80),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: LuxuryTheme.purpleLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [LuxuryTheme.purpleLight, LuxuryTheme.gold],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              "No appointments yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your bookings will appear here",
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
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
      color: LuxuryTheme.black,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: appointmentRepo.getUserAppointments(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: LuxuryTheme.purple,
              ),
            );
          }

          final all = snapshot.data!;

          final upcoming = all
              .where((a) =>
                  a.status == 'pending' || a.status == 'approved')
              .toList();

          final history = all
              .where((a) =>
                  a.status == 'completed' || a.status == 'cancelled')
              .toList();

          if (all.isEmpty) {
            return _emptyState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader("Upcoming Appointments", upcoming.length),
                ...upcoming.map(_buildCard),
                const SizedBox(height: 8),
              ],
              if (history.isNotEmpty) ...[
                _sectionHeader("History", history.length),
                ...history.map(_buildCard),
              ],
            ],
          );
        },
      ),
    );
  }
}
