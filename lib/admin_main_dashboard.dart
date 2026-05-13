import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

/// Callback so dashboard tiles can switch the parent nav tab
typedef OnNavTap = void Function(int index);

class AdminMainDashboard extends StatelessWidget {
  final OnNavTap onNavTap;
  const AdminMainDashboard({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, adminSnap) {
          final adminData =
              adminSnap.data?.data() as Map<String, dynamic>? ?? {};
          final adminName = adminData['name'] as String? ?? 'Admin';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .snapshots(),
            builder: (context, apptSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, userSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .orderBy('createdAt', descending: true)
                        .limit(6)
                        .snapshots(),
                    builder: (context, recentSnap) {
                      // ── Compute stats ──────────────────────────────
                      final allAppts = (apptSnap.data?.docs ?? [])
                          .map((d) => AppointmentModel.fromDoc(d))
                          .toList();

                      final allUsers = userSnap.data?.docs ?? [];

                      final totalUsers = allUsers.length;
                      final totalBookings = allAppts.length;
                      final pending = allAppts
                          .where((a) => a.status == 'pending')
                          .length;
                      final approved = allAppts
                          .where((a) => a.status == 'approved')
                          .length;

                      // Today's revenue
                      final today = DateTime.now();
                      final todayRevenue = allAppts
                          .where((a) =>
                              a.status == 'completed' &&
                              a.date.year == today.year &&
                              a.date.month == today.month &&
                              a.date.day == today.day)
                          .fold<double>(
                              0, (s, a) => s + a.price.toDouble());

                      // Total revenue (all time)
                      final totalRevenue = allAppts
                          .where((a) => a.status == 'completed')
                          .fold<double>(
                              0, (s, a) => s + a.price.toDouble());

                      // Top services
                      final svcCount = <String, int>{};
                      for (final a in allAppts) {
                        svcCount[a.serviceName] =
                            (svcCount[a.serviceName] ?? 0) + 1;
                      }
                      final topServices = svcCount.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      // Monthly revenue (last 6 months)
                      final monthlyRev = <String, double>{};
                      for (final a in allAppts
                          .where((a) => a.status == 'completed')) {
                        final k = DateFormat('MMM yy').format(a.date);
                        monthlyRev[k] =
                            (monthlyRev[k] ?? 0) + a.price.toDouble();
                      }

                      // Recent appointments
                      final recent = (recentSnap.data?.docs ?? [])
                          .map((d) => AppointmentModel.fromDoc(d))
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 24),
                        children: [
                          // ── Welcome header ─────────────────────────
                          _buildWelcome(
                              context, adminName, user?.uid ?? ''),
                          const SizedBox(height: 20),

                          // ── Live stats ─────────────────────────────
                          _sectionLabel('Live Overview'),
                          const SizedBox(height: 12),
                          _buildStatsGrid(
                            totalUsers: totalUsers,
                            totalBookings: totalBookings,
                            pending: pending,
                            approved: approved,
                            todayRevenue: todayRevenue,
                            totalRevenue: totalRevenue,
                          ),
                          const SizedBox(height: 20),

                          // ── Quick actions ──────────────────────────
                          _sectionLabel('Quick Actions'),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 20),

                          // ── Monthly revenue chart ──────────────────
                          if (monthlyRev.length > 1) ...[
                            _sectionLabel('Monthly Revenue'),
                            const SizedBox(height: 12),
                            _buildRevenueChart(monthlyRev),
                            const SizedBox(height: 20),
                          ],

                          // ── Top services ───────────────────────────
                          if (topServices.isNotEmpty) ...[
                            _sectionLabel('Top Services'),
                            const SizedBox(height: 12),
                            _buildTopServices(
                                topServices.take(5).toList(),
                                totalBookings),
                            const SizedBox(height: 20),
                          ],

                          // ── Recent activity ────────────────────────
                          if (recent.isNotEmpty) ...[
                            _sectionLabel('Recent Activity'),
                            const SizedBox(height: 12),
                            _buildRecentActivity(recent),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Welcome header ──────────────────────────────────────────────────────────
  Widget _buildWelcome(
      BuildContext context, String name, String uid) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            LuxuryTheme.purple.withAlpha(80),
            LuxuryTheme.purpleDim.withAlpha(140),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: LuxuryTheme.purpleLight.withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: LuxuryTheme.purple.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        ProfileAvatarWidget(name: name, uid: uid, size: 60),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LuxuryTheme.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: LuxuryTheme.gold.withAlpha(80)),
              ),
              child: const Text('Administrator',
                  style: TextStyle(
                      color: LuxuryTheme.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ],
        )),
        // Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('EEE').format(DateTime.now()),
                style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 11)),
            Text(DateFormat('d MMM').format(DateTime.now()),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ]),
    );
  }

  // ── Stats grid ──────────────────────────────────────────────────────────────
  Widget _buildStatsGrid({
    required int totalUsers,
    required int totalBookings,
    required int pending,
    required int approved,
    required double todayRevenue,
    required double totalRevenue,
  }) {
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(
          icon: Icons.people_rounded,
          label: 'Total Users',
          value: '$totalUsers',
          color: LuxuryTheme.purpleLight,
          sub: 'registered',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.calendar_month_rounded,
          label: 'Total Bookings',
          value: '$totalBookings',
          color: const Color(0xFF64B5F6),
          sub: 'all time',
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard(
          icon: Icons.hourglass_empty_rounded,
          label: 'Pending',
          value: '$pending',
          color: Colors.orange,
          sub: 'awaiting approval',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.check_circle_rounded,
          label: 'Approved',
          value: '$approved',
          color: Colors.green,
          sub: 'confirmed',
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard(
          icon: Icons.today_rounded,
          label: "Today's Revenue",
          value: 'LKR ${_fmt(todayRevenue)}',
          color: LuxuryTheme.gold,
          sub: 'completed today',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.payments_rounded,
          label: 'Total Revenue',
          value: 'LKR ${_fmt(totalRevenue)}',
          color: LuxuryTheme.goldLight,
          sub: 'all time',
        )),
      ]),
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style: TextStyle(
                    color: Colors.white.withAlpha(70),
                    fontSize: 9)),
          ],
        )),
      ]),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.content_cut_rounded,
        label: 'Services',
        sub: 'Add · Edit · Delete',
        color: LuxuryTheme.purpleLight,
        navIndex: 1,
      ),
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Bookings',
        sub: 'Approve · Complete',
        color: const Color(0xFF64B5F6),
        navIndex: 2,
      ),
      _QuickAction(
        icon: Icons.people_rounded,
        label: 'Users',
        sub: 'Manage roles',
        color: Colors.green,
        navIndex: 3,
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        label: 'Profile',
        sub: 'Admin settings',
        color: LuxuryTheme.gold,
        navIndex: 4,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: actions.map((a) => GestureDetector(
        onTap: () => onNavTap(a.navIndex),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: a.color.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                  color: a.color.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: a.color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(a.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(a.sub,
                    style: TextStyle(
                        color: Colors.white.withAlpha(100),
                        fontSize: 10)),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded,
                color: a.color.withAlpha(120), size: 12),
          ]),
        ),
      )).toList(),
    );
  }

  // ── Monthly revenue chart ───────────────────────────────────────────────────
  Widget _buildRevenueChart(Map<String, double> data) {
    final entries = data.entries.toList()
        .reversed.take(6).toList().reversed.toList();
    final maxVal = entries.map((e) => e.value).reduce(
        (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LKR ${_fmt(entries.map((e) => e.value).fold(0.0, (a, b) => a + b))}',
                  style: const TextStyle(
                      color: LuxuryTheme.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text('Last ${entries.length} months',
                  style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((e) {
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                final isMax = e.value == maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(_fmtShort(e.value),
                            style: TextStyle(
                                color: isMax
                                    ? LuxuryTheme.gold
                                    : LuxuryTheme.purpleLight.withAlpha(180),
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          height: (ratio * 72).clamp(4.0, 72.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isMax
                                  ? [LuxuryTheme.gold, LuxuryTheme.goldLight]
                                  : [LuxuryTheme.purple, LuxuryTheme.purpleLight],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color: (isMax
                                          ? LuxuryTheme.gold
                                          : LuxuryTheme.purple)
                                      .withAlpha(80),
                                  blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(e.key,
                            style: TextStyle(
                                color: Colors.white.withAlpha(120),
                                fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top services ────────────────────────────────────────────────────────────
  Widget _buildTopServices(
      List<MapEntry<String, int>> services, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(
        children: services.asMap().entries.map((entry) {
          final rank  = entry.key + 1;
          final svc   = entry.value;
          final pct   = total > 0 ? svc.value / total : 0.0;
          final color = rank == 1
              ? LuxuryTheme.gold
              : rank == 2
                  ? LuxuryTheme.purpleLight
                  : Colors.white54;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(children: [
                  // Rank badge
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Center(
                      child: Text('$rank',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(svc.key,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${svc.value} bookings',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withAlpha(15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        color.withAlpha(180)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Recent activity ─────────────────────────────────────────────────────────
  Widget _buildRecentActivity(List<AppointmentModel> recent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(
        children: recent.map((a) {
          final statusColor = _statusColor(a.status);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              // Status dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              // Date block
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: LuxuryTheme.purple.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('dd').format(a.date),
                        style: const TextStyle(
                            color: LuxuryTheme.purpleLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    Text(DateFormat('MMM').format(a.date),
                        style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 8,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.serviceName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(a.userName,
                      style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 11)),
                ],
              )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LKR ${a.price}',
                      style: const TextStyle(
                          color: LuxuryTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: statusColor.withAlpha(80)),
                    ),
                    child: Text(a.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                  ),
                ],
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
          color: LuxuryTheme.purpleLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    ]),
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':  return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.redAccent;
      default:          return Colors.orange;
    }
  }

  String _fmt(double v) =>
      v >= 1000 ? NumberFormat('#,##0').format(v) : v.toStringAsFixed(0);

  String _fmtShort(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final int navIndex;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.navIndex,
  });
}
