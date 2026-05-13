import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

class BeauticianHomeDashboard extends StatelessWidget {
  final void Function(int) onNavTap;
  const BeauticianHomeDashboard({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now  = DateTime.now();

    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final data = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] as String? ?? 'Beautician';

          return StreamBuilder<List<AppointmentModel>>(
            stream: AppointmentRepo().getAllAppointments(),
            builder: (context, apptSnap) {
              final all = apptSnap.data ?? [];

              // Today's appointments
              final todayAll = all.where((a) =>
                  a.date.year == now.year &&
                  a.date.month == now.month &&
                  a.date.day == now.day).toList()
                ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

              final todayApproved = todayAll.where((a) => a.status == 'approved').toList();
              final todayDone     = todayAll.where((a) => a.status == 'completed').toList();
              final todayEarnings = todayDone.fold<double>(0, (s, a) => s + a.price.toDouble());

              // Next upcoming approved job
              final nextJob = todayApproved.isNotEmpty ? todayApproved.first : null;

              // All pending across all days
              final allPending = all.where((a) => a.status == 'pending').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // ── Welcome header ──────────────────────────────────
                  _buildWelcome(name, user?.uid ?? ''),
                  const SizedBox(height: 18),

                  // ── Stats row ───────────────────────────────────────
                  _sectionLabel('Today at a Glance'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _statCard(
                      icon: Icons.work_rounded,
                      label: "Today's Jobs",
                      value: '${todayAll.length}',
                      color: LuxuryTheme.purpleLight,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard(
                      icon: Icons.payments_rounded,
                      label: "Today's Earnings",
                      value: 'LKR ${_fmt(todayEarnings)}',
                      color: LuxuryTheme.gold,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard(
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Pending',
                      value: '$allPending',
                      color: Colors.orange,
                    )),
                  ]),
                  const SizedBox(height: 18),

                  // ── Next job ────────────────────────────────────────
                  _sectionLabel('Next Upcoming Job'),
                  const SizedBox(height: 10),
                  nextJob != null
                      ? _buildNextJobCard(context, nextJob)
                      : _buildNoNextJob(),
                  const SizedBox(height: 18),

                  // ── Today's schedule ────────────────────────────────
                  _sectionLabel("Today's Schedule"),
                  const SizedBox(height: 10),
                  todayAll.isEmpty
                      ? _buildEmptySchedule()
                      : _buildScheduleTimeline(todayAll),
                  const SizedBox(height: 18),

                  // ── Quick actions ───────────────────────────────────
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _quickAction(
                      icon: Icons.work_outline_rounded,
                      label: 'All Jobs',
                      sub: '$allPending pending',
                      color: LuxuryTheme.purpleLight,
                      onTap: () => onNavTap(1),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _quickAction(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'History',
                      sub: '${todayDone.length} today',
                      color: Colors.green,
                      onTap: () => onNavTap(2),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _quickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Earnings',
                      sub: 'View report',
                      color: LuxuryTheme.gold,
                      onTap: () => onNavTap(3),
                    )),
                  ]),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Welcome header ──────────────────────────────────────────────────────────
  Widget _buildWelcome(String name, String uid) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [LuxuryTheme.purple.withAlpha(80), LuxuryTheme.purpleDim.withAlpha(140)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(60)),
        boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        ProfileAvatarWidget(name: name, uid: uid, size: 56),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: LuxuryTheme.purpleLight.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(80)),
            ),
            child: const Text('Beautician', style: TextStyle(color: LuxuryTheme.purpleLight, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(DateFormat('EEE').format(DateTime.now()), style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
          Text(DateFormat('d MMM').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  // ── Next job card ───────────────────────────────────────────────────────────
  Widget _buildNextJobCard(BuildContext context, AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.schedule_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text('Next: ${a.timeSlot}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('APPROVED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(a.serviceName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(a.userName, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          _nextJobDetail(Icons.timer_outlined, '${a.duration} min'),
          const SizedBox(width: 16),
          _nextJobDetail(Icons.payments_outlined, 'LKR ${a.price}'),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            await AppointmentRepo().updateStatus(a.id, 'completed');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Job marked as completed ✅'),
                backgroundColor: LuxuryTheme.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Mark as Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _nextJobDetail(IconData icon, String text) => Row(children: [
    Icon(icon, color: Colors.white70, size: 14),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
  ]);

  Widget _buildNoNextJob() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: LuxuryTheme.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
    ),
    child: Row(children: [
      Icon(Icons.event_available_rounded, color: LuxuryTheme.purpleLight.withAlpha(120), size: 32),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('No upcoming jobs today', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('Check back later', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12)),
      ]),
    ]),
  );

  // ── Schedule timeline ───────────────────────────────────────────────────────
  Widget _buildScheduleTimeline(List<AppointmentModel> jobs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
      ),
      child: Column(
        children: jobs.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final isLast = i == jobs.length - 1;
          final statusColor = _statusColor(a.status);

          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Timeline indicator
            Column(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: statusColor.withAlpha(80), blurRadius: 6)]),
              ),
              if (!isLast) Container(width: 2, height: 52, color: LuxuryTheme.purple.withAlpha(40)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.timeSlot, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(a.serviceName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  Text(a.userName, style: TextStyle(color: LuxuryTheme.purpleLight.withAlpha(180), fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('LKR ${a.price}', style: const TextStyle(color: LuxuryTheme.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withAlpha(80)),
                    ),
                    child: Text(a.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ),
                ]),
              ]),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildEmptySchedule() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: LuxuryTheme.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
    ),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.calendar_today_rounded, color: LuxuryTheme.purpleLight.withAlpha(80), size: 36),
      const SizedBox(height: 10),
      const Text('No appointments today', style: TextStyle(color: Colors.white54, fontSize: 13)),
    ])),
  );

  // ── Quick action tile ───────────────────────────────────────────────────────
  Widget _quickAction({required IconData icon, required String label, required String sub, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: LuxuryTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
          boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _statCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: LuxuryTheme.purpleLight, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':  return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.redAccent;
      default:          return Colors.orange;
    }
  }

  String _fmt(double v) => v >= 1000 ? NumberFormat('#,##0').format(v) : v.toStringAsFixed(0);
}
