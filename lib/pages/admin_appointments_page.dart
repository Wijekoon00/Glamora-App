import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import '../services/appointment_repo.dart';
import '../widgets/luxury_form_widgets.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  final repo = AppointmentRepo();

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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_rounded;
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

  // ── Summary stats row ───────────────────────────────────────────────────────
  Widget _buildStatsRow(List<AppointmentModel> appointments) {
    final total = appointments.length;
    final pending = appointments.where((a) => a.status == 'pending').length;
    final approved = appointments.where((a) => a.status == 'approved').length;
    final completed = appointments.where((a) => a.status == 'completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildStatCard("Total", total, Icons.calendar_month_rounded,
              LuxuryTheme.purpleLight),
          const SizedBox(width: 8),
          _buildStatCard(
              "Pending", pending, Icons.hourglass_empty_rounded, Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard(
              "Approved", approved, Icons.check_circle_outline_rounded, Colors.green),
          const SizedBox(width: 8),
          _buildStatCard(
              "Done", completed, Icons.done_all_rounded, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: LuxuryTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: LuxuryTheme.purple.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons(AppointmentModel a) {
    if (a.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _gradientButton(
              label: "Approve",
              colors: [const Color(0xFF1B8A3E), const Color(0xFF27AE60)],
              shadowColor: const Color(0xFF27AE60),
              onTap: () => _updateStatus(a.id, 'approved'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _gradientButton(
              label: "Cancel",
              colors: [const Color(0xFFB71C1C), const Color(0xFFE53935)],
              shadowColor: const Color(0xFFE53935),
              onTap: () => _updateStatus(a.id, 'cancelled'),
            ),
          ),
        ],
      );
    }

    if (a.status == 'approved') {
      return _gradientButton(
        label: "Mark Completed",
        colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
        shadowColor: LuxuryTheme.purple,
        onTap: () => _updateStatus(a.id, 'completed'),
        fullWidth: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _gradientButton({
    required String label,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── Appointment card ────────────────────────────────────────────────────────
  Widget _buildAppointmentCard(AppointmentModel a) {
    final statusColor = _statusColor(a.status);

    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              color: LuxuryTheme.purpleLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            a.userName,
                            style: const TextStyle(
                              color: LuxuryTheme.purpleLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(180)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(a.status),
                          color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        a.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Detail grid (2 columns) ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuxuryTheme.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LuxuryTheme.purple.withAlpha(30)),
              ),
              child: Row(
                children: [
                  // Left column: date & time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailItem(
                          icon: Icons.calendar_today_rounded,
                          label: "Date",
                          value: DateFormat('yyyy-MM-dd').format(a.date),
                        ),
                        const SizedBox(height: 10),
                        _detailItem(
                          icon: Icons.access_time_rounded,
                          label: "Time",
                          value: a.timeSlot,
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 50,
                    color: LuxuryTheme.purple.withAlpha(40),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Right column: price & duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailItem(
                          icon: Icons.attach_money_rounded,
                          label: "Price",
                          value: "${a.price} LKR",
                        ),
                        const SizedBox(height: 10),
                        _detailItem(
                          icon: Icons.timer_outlined,
                          label: "Duration",
                          value: "${a.duration} mins",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────────────────────────
            _buildActionButtons(a),
          ],
        ),
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: LuxuryTheme.purple, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxuryTheme.purple.withAlpha(30),
              border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: LuxuryTheme.purple.withAlpha(40),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: LuxuryTheme.purpleLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
            ).createShader(bounds),
            child: const Text(
              "No Appointments Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Appointments will appear here once booked.",
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
    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: repo.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: LuxuryTheme.purple,
                strokeWidth: 2.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.white.withAlpha(160)),
              ),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildStatsRow(appointments),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildAppointmentCard(appointments[index]),
                      );
                    },
                    childCount: appointments.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
