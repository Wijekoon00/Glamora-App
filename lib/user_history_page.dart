import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class UserHistoryPage extends StatelessWidget {
  final void Function(int)? onNavTap;
  const UserHistoryPage({super.key, this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('User not found',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<List<AppointmentModel>>(
        stream: AppointmentRepo().getUserAppointments(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: LuxuryTheme.purpleLight),
            );
          }

          final all = snapshot.data!;

          // Only completed appointments count as real history
          final completed = all
              .where((a) => a.status == 'completed')
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (completed.isEmpty) {
            return _buildEmptyState();
          }

          // ── Compute stats ──────────────────────────────────────────────
          final totalSpent = completed.fold<double>(
              0, (sum, a) => sum + a.price.toDouble());
          final totalVisits = completed.length;
          final totalMinutes =
              completed.fold<int>(0, (sum, a) => sum + a.duration);

          // Favourite service
          final serviceCount = <String, int>{};
          for (final a in completed) {
            serviceCount[a.serviceName] =
                (serviceCount[a.serviceName] ?? 0) + 1;
          }
          final favourite = serviceCount.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;

          // Monthly spending map
          final monthlySpend = <String, double>{};
          for (final a in completed) {
            final key = DateFormat('MMM yy').format(a.date);
            monthlySpend[key] =
                (monthlySpend[key] ?? 0) + a.price.toDouble();
          }

          // Group by month for the list
          final grouped = <String, List<AppointmentModel>>{};
          for (final a in completed) {
            final key = DateFormat('MMMM yyyy').format(a.date);
            grouped.putIfAbsent(key, () => []).add(a);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ── Summary cards ────────────────────────────────────────
              _buildSummaryRow(
                  totalSpent, totalVisits, totalMinutes),
              const SizedBox(height: 16),

              // ── Favourite service ────────────────────────────────────
              _buildFavouriteCard(favourite,
                  serviceCount[favourite] ?? 0),
              const SizedBox(height: 16),

              // ── Monthly spending chart ───────────────────────────────
              if (monthlySpend.length > 1) ...[
                _buildSpendingChart(monthlySpend),
                const SizedBox(height: 16),
              ],

              // ── History list grouped by month ────────────────────────
              ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _monthHeader(entry.key, entry.value),
                  const SizedBox(height: 10),
                  ...entry.value.map(_buildHistoryCard),
                  const SizedBox(height: 16),
                ],
              )),
            ],
          );
        },
      ),
    );
  }

  // ── Summary row ─────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(
      double totalSpent, int visits, int minutes) {
    return Row(children: [
      Expanded(child: _statCard(
        icon: Icons.payments_rounded,
        label: 'Total Spent',
        value: 'LKR ${_fmt(totalSpent)}',
        color: LuxuryTheme.gold,
      )),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
        icon: Icons.event_available_rounded,
        label: 'Visits',
        value: '$visits',
        color: LuxuryTheme.purpleLight,
      )),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
        icon: Icons.timer_rounded,
        label: 'Hours',
        value: '${(minutes / 60).toStringAsFixed(1)}h',
        color: const Color(0xFF4DB6AC),
      )),
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Favourite service card ───────────────────────────────────────────────────
  Widget _buildFavouriteCard(String service, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuxuryTheme.gold.withAlpha(60)),
        gradient: LinearGradient(
          colors: [
            LuxuryTheme.purpleDim.withAlpha(80),
            LuxuryTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: LuxuryTheme.gold.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.star_rounded,
              color: LuxuryTheme.gold, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favourite Service',
                style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(service,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: LuxuryTheme.gold.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: LuxuryTheme.gold.withAlpha(80)),
          ),
          child: Text('$count×',
              style: const TextStyle(
                  color: LuxuryTheme.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Monthly spending bar chart ───────────────────────────────────────────────
  Widget _buildSpendingChart(Map<String, double> data) {
    // Take last 6 months
    final entries = data.entries.toList().reversed.take(6).toList().reversed.toList();
    final maxVal = entries.map((e) => e.value).reduce(
        (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 3, height: 16,
              decoration: BoxDecoration(
                color: LuxuryTheme.purpleLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Monthly Spending',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((e) {
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Text(
                          _fmtShort(e.value),
                          style: TextStyle(
                              color: LuxuryTheme.purpleLight.withAlpha(200),
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: (ratio * 80).clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LuxuryTheme.purple,
                                LuxuryTheme.purpleLight,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                  color: LuxuryTheme.purple.withAlpha(80),
                                  blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Month label
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

  // ── Month section header ─────────────────────────────────────────────────────
  Widget _monthHeader(String month, List<AppointmentModel> items) {
    final monthTotal = items.fold<double>(
        0, (s, a) => s + a.price.toDouble());
    return Row(children: [
      Container(
        width: 3, height: 16,
        decoration: BoxDecoration(
          color: LuxuryTheme.purpleLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(month,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: LuxuryTheme.purple.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: LuxuryTheme.purple.withAlpha(80)),
        ),
        child: Text('LKR ${_fmt(monthTotal)}',
            style: const TextStyle(
                color: LuxuryTheme.purpleLight,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  // ── Individual history card ──────────────────────────────────────────────────
  Widget _buildHistoryCard(AppointmentModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(50)),
      ),
      child: Row(children: [
        // Date block
        Container(
          width: 48, height: 56,
          decoration: BoxDecoration(
            color: LuxuryTheme.purple.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: LuxuryTheme.purple.withAlpha(80)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(a.date),
                style: const TextStyle(
                    color: LuxuryTheme.purpleLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ),
              Text(
                DateFormat('MMM').format(a.date).toUpperCase(),
                style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.serviceName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  color: Colors.white.withAlpha(100), size: 12),
              const SizedBox(width: 4),
              Text(a.timeSlot,
                  style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 12)),
              const SizedBox(width: 10),
              Icon(Icons.timer_outlined,
                  color: Colors.white.withAlpha(100), size: 12),
              const SizedBox(width: 4),
              Text('${a.duration} min',
                  style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 12)),
            ]),
          ],
        )),

        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('LKR ${_fmt(a.price.toDouble())}',
                style: const TextStyle(
                    color: LuxuryTheme.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.blue.withAlpha(80)),
              ),
              child: const Text('DONE',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
            if (onNavTap != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => onNavTap!(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(80), blurRadius: 6)],
                  ),
                  child: const Text('Book Again', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ]),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxuryTheme.purple.withAlpha(30),
              border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(60)),
              boxShadow: [
                BoxShadow(
                    color: LuxuryTheme.purple.withAlpha(40),
                    blurRadius: 24),
              ],
            ),
            child: const Icon(Icons.history_rounded,
                color: LuxuryTheme.purpleLight, size: 40),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [LuxuryTheme.purpleLight, LuxuryTheme.gold],
            ).createShader(b),
            child: const Text('No history yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed appointments will appear here\nwith your full spending history.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 13,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _fmt(double v) {
    if (v >= 1000) {
      return NumberFormat('#,##0').format(v);
    }
    return v.toStringAsFixed(0);
  }

  String _fmtShort(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
