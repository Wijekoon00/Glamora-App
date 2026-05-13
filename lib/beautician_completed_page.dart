import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianCompletedPage extends StatefulWidget {
  const BeauticianCompletedPage({super.key});

  @override
  State<BeauticianCompletedPage> createState() =>
      _BeauticianCompletedPageState();
}

class _BeauticianCompletedPageState extends State<BeauticianCompletedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LuxuryTheme.black,
      child: Column(children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            border: Border(
              bottom: BorderSide(
                  color: LuxuryTheme.purpleLight.withAlpha(40), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tab,
            indicatorColor: LuxuryTheme.purpleLight,
            indicatorWeight: 2,
            labelColor: LuxuryTheme.purpleLight,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.today_rounded, size: 16),
                  text: 'Daily'),
              Tab(icon: Icon(Icons.view_week_rounded, size: 16),
                  text: 'Weekly'),
              Tab(icon: Icon(Icons.calendar_month_rounded, size: 16),
                  text: 'Monthly'),
            ],
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: AppointmentRepo().getAllAppointments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: LuxuryTheme.purpleLight),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white54)),
                );
              }

              final completed = (snapshot.data ?? [])
                  .where((a) => a.status == 'completed')
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              return TabBarView(
                controller: _tab,
                children: [
                  _HistoryView(
                    appointments: completed,
                    period: _Period.daily,
                  ),
                  _HistoryView(
                    appointments: completed,
                    period: _Period.weekly,
                  ),
                  _HistoryView(
                    appointments: completed,
                    period: _Period.monthly,
                  ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
enum _Period { daily, weekly, monthly }

// ─────────────────────────────────────────────────────────────────────────────
class _HistoryView extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final _Period period;

  const _HistoryView({
    required this.appointments,
    required this.period,
  });

  // ── Filter appointments to the current period ──────────────────────────────
  List<AppointmentModel> get _filtered {
    final now = DateTime.now();
    return appointments.where((a) {
      switch (period) {
        case _Period.daily:
          return a.date.year == now.year &&
              a.date.month == now.month &&
              a.date.day == now.day;
        case _Period.weekly:
          final startOfWeek =
              now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return a.date.isAfter(
                  startOfWeek.subtract(const Duration(seconds: 1))) &&
              a.date.isBefore(
                  endOfWeek.add(const Duration(days: 1)));
        case _Period.monthly:
          return a.date.year == now.year &&
              a.date.month == now.month;
      }
    }).toList();
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (period) {
      case _Period.daily:
        return DateFormat('EEEE, MMM d').format(now);
      case _Period.weekly:
        final start =
            now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
      case _Period.monthly:
        return DateFormat('MMMM yyyy').format(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    // ── Stats ──────────────────────────────────────────────────────────
    final totalJobs = list.length;
    final totalRevenue =
        list.fold<double>(0, (s, a) => s + a.price.toDouble());
    final totalMins =
        list.fold<int>(0, (s, a) => s + a.duration);

    // Service breakdown
    final svcMap = <String, int>{};
    for (final a in list) {
      svcMap[a.serviceName] = (svcMap[a.serviceName] ?? 0) + 1;
    }
    final topSvc = svcMap.entries.isEmpty
        ? null
        : svcMap.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (list.isEmpty) {
      return _emptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // ── Period label ───────────────────────────────────────────────
        Row(children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color: LuxuryTheme.purpleLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(_periodLabel,
              style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),

        // ── Stats row ──────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _statCard(
            icon: Icons.check_circle_rounded,
            label: 'Jobs Done',
            value: '$totalJobs',
            color: Colors.green,
          )),
          const SizedBox(width: 10),
          Expanded(child: _statCard(
            icon: Icons.payments_rounded,
            label: 'Revenue',
            value: 'LKR ${_fmt(totalRevenue)}',
            color: LuxuryTheme.gold,
          )),
          const SizedBox(width: 10),
          Expanded(child: _statCard(
            icon: Icons.timer_rounded,
            label: 'Hours',
            value: '${(totalMins / 60).toStringAsFixed(1)}h',
            color: LuxuryTheme.purpleLight,
          )),
        ]),
        const SizedBox(height: 12),

        // ── Top service this period ────────────────────────────────────
        if (topSvc != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LuxuryTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: LuxuryTheme.gold.withAlpha(60)),
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: LuxuryTheme.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded,
                    color: LuxuryTheme.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Service',
                      style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(topSvc.key,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                child: Text('${topSvc.value}×',
                    style: const TextStyle(
                        color: LuxuryTheme.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ── Service breakdown bar chart ────────────────────────────────
        if (svcMap.length > 1) ...[
          _buildServiceBreakdown(svcMap, totalJobs),
          const SizedBox(height: 14),
        ],

        // ── Job list ───────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: LuxuryTheme.purpleLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Completed Jobs',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$totalJobs total',
              style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 11)),
        ]),
        const SizedBox(height: 10),

        ...list.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CompletedCard(appointment: a),
        )),
      ],
    );
  }

  Widget _buildServiceBreakdown(
      Map<String, int> svcMap, int total) {
    final sorted = svcMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Breakdown',
              style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...sorted.take(4).map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${e.value} job${e.value > 1 ? 's' : ''}',
                        style: TextStyle(
                            color: LuxuryTheme.purpleLight.withAlpha(200),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          LuxuryTheme.purpleLight.withAlpha(180)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _emptyState() {
    final labels = {
      _Period.daily:   'No jobs completed today',
      _Period.weekly:  'No jobs completed this week',
      _Period.monthly: 'No jobs completed this month',
    };
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
          Text(labels[period]!,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Completed jobs will appear here',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? NumberFormat('#,##0').format(v) : v.toStringAsFixed(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable completed job card
// ─────────────────────────────────────────────────────────────────────────────
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.appointment});
  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
        boxShadow: [
          BoxShadow(
              color: LuxuryTheme.purple.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        // Date block
        Container(
          width: 46, height: 54,
          decoration: BoxDecoration(
            color: LuxuryTheme.purple.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: LuxuryTheme.purple.withAlpha(80)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('dd').format(a.date),
                  style: const TextStyle(
                      color: LuxuryTheme.purpleLight,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              Text(DateFormat('MMM').format(a.date).toUpperCase(),
                  style: TextStyle(
                      color: Colors.white.withAlpha(140),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
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
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(a.userName,
                style: TextStyle(
                    color: LuxuryTheme.purpleLight.withAlpha(180),
                    fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  color: Colors.white.withAlpha(80), size: 12),
              const SizedBox(width: 4),
              Text(a.timeSlot,
                  style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 11)),
              const SizedBox(width: 10),
              Icon(Icons.timer_outlined,
                  color: Colors.white.withAlpha(80), size: 12),
              const SizedBox(width: 4),
              Text('${a.duration} min',
                  style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 11)),
            ]),
          ],
        )),

        // Price + badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('LKR ${a.price}',
                style: const TextStyle(
                    color: LuxuryTheme.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
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
          ],
        ),
      ]),
    );
  }
}
