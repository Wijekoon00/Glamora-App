import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianJobsPage extends StatefulWidget {
  const BeauticianJobsPage({super.key});

  @override
  State<BeauticianJobsPage> createState() => _BeauticianJobsPageState();
}

class _BeauticianJobsPageState extends State<BeauticianJobsPage> {
  final repo = AppointmentRepo();

  bool _loading = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: LuxuryTheme.card,
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
            child: _GradientButton(
              label: "Approve",
              colors: [Colors.green.shade700, Colors.green],
              onPressed: _loading ? null : () => _updateStatus(a.id, 'approved'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GradientButton(
              label: "Cancel",
              colors: [Colors.red.shade800, Colors.redAccent],
              onPressed: _loading ? null : () => _updateStatus(a.id, 'cancelled'),
            ),
          ),
        ],
      );
    }

    if (a.status == 'approved') {
      return _GradientButton(
        label: "Mark Completed",
        colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
        fullWidth: true,
        glowColor: LuxuryTheme.purple,
        onPressed: _loading ? null : () => _updateStatus(a.id, 'completed'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: LuxuryTheme.purpleLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
                color: LuxuryTheme.purpleLight,
              ),
            );
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryTheme.purple.withAlpha(40),
                      border: Border.all(
                        color: LuxuryTheme.purple.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: LuxuryTheme.purpleLight,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No active appointments",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = appointments[index];
              final statusColor = _statusColor(a.status);

              return Container(
                decoration: BoxDecoration(
                  color: LuxuryTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: LuxuryTheme.purple.withAlpha(60),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryTheme.purple.withAlpha(30),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card header ──────────────────────────────────────
                      Text(
                        a.serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.userName,
                        style: TextStyle(
                          color: LuxuryTheme.purpleLight.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Detail grid (2 columns) ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailItem(
                                  Icons.calendar_today_rounded,
                                  DateFormat('yyyy-MM-dd').format(a.date),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailItem(
                                  Icons.access_time_rounded,
                                  a.timeSlot,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailItem(
                                  Icons.payments_outlined,
                                  "${a.price} LKR",
                                ),
                                const SizedBox(height: 8),
                                _buildDetailItem(
                                  Icons.timer_outlined,
                                  "${a.duration} mins",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Status badge ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(38),
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
                      const SizedBox(height: 14),

                      // ── Action buttons ───────────────────────────────────
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

// ── Internal gradient button helper ──────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onPressed,
    this.fullWidth = false,
    this.glowColor,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 42,
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1.0,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor!.withAlpha(100),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
