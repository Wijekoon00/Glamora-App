import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianEarningsPage extends StatefulWidget {
  const BeauticianEarningsPage({super.key});

  @override
  State<BeauticianEarningsPage> createState() => _BeauticianEarningsPageState();
}

class _BeauticianEarningsPageState extends State<BeauticianEarningsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

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
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            border: Border(bottom: BorderSide(color: LuxuryTheme.purpleLight.withAlpha(40), width: 1)),
          ),
          child: TabBar(
            controller: _tab,
            indicatorColor: LuxuryTheme.gold,
            indicatorWeight: 2,
            labelColor: LuxuryTheme.gold,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.today_rounded, size: 15), text: 'Daily'),
              Tab(icon: Icon(Icons.view_week_rounded, size: 15), text: 'Weekly'),
              Tab(icon: Icon(Icons.calendar_month_rounded, size: 15), text: 'Monthly'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: AppointmentRepo().getAllAppointments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold));
              }
              final completed = (snapshot.data ?? [])
                  .where((a) => a.status == 'completed')
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              return TabBarView(
                controller: _tab,
                children: [
                  _EarningsView(appointments: completed, period: _Period.daily),
                  _EarningsView(appointments: completed, period: _Period.weekly),
                  _EarningsView(appointments: completed, period: _Period.monthly),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

enum _Period { daily, weekly, monthly }

class _EarningsView extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final _Period period;

  const _EarningsView({required this.appointments, required this.period});

  List<AppointmentModel> get _filtered {
    final now = DateTime.now();
    return appointments.where((a) {
      switch (period) {
        case _Period.daily:
          return a.date.year == now.year && a.date.month == now.month && a.date.day == now.day;
        case _Period.weekly:
          final start = now.subtract(Duration(days: now.weekday - 1));
          final end   = start.add(const Duration(days: 6));
          return !a.date.isBefore(DateTime(start.year, start.month, start.day)) &&
              !a.date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
        case _Period.monthly:
          return a.date.year == now.year && a.date.month == now.month;
      }
    }).toList();
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (period) {
      case _Period.daily:   return DateFormat('EEEE, MMM d').format(now);
      case _Period.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end   = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
      case _Period.monthly: return DateFormat('MMMM yyyy').format(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    if (list.isEmpty) return _emptyState();

    final totalEarned = list.fold<double>(0, (s, a) => s + a.price.toDouble());
    final totalJobs   = list.length;
    final totalMins   = list.fold<int>(0, (s, a) => s + a.duration);
    final avgPerJob   = totalJobs > 0 ? totalEarned / totalJobs : 0.0;

    // Monthly chart data (only for monthly tab)
    final Map<String, double> monthlyData = {};
    if (period == _Period.monthly) {
      for (final a in appointments) {
        final k = DateFormat('MMM yy').format(a.date);
        monthlyData[k] = (monthlyData[k] ?? 0) + a.price.toDouble();
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Period label
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(_periodLabel, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),

        // Big earnings display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(100), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            Text('Total Earned', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [LuxuryTheme.goldLight, LuxuryTheme.gold]).createShader(b),
              child: Text('LKR ${_fmt(totalEarned)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 4),
            Text('$totalJobs job${totalJobs != 1 ? 's' : ''} completed',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),

        // 4 stat cards
        Row(children: [
          Expanded(child: _statCard(Icons.payments_rounded, 'Earned', 'LKR ${_fmt(totalEarned)}', LuxuryTheme.gold)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.check_circle_rounded, 'Jobs', '$totalJobs', Colors.green)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statCard(Icons.timer_rounded, 'Hours', '${(totalMins / 60).toStringAsFixed(1)}h', LuxuryTheme.purpleLight)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.trending_up_rounded, 'Avg/Job', 'LKR ${_fmt(avgPerJob)}', const Color(0xFF64B5F6))),
        ]),
        const SizedBox(height: 16),

        // Monthly chart (only in monthly tab)
        if (period == _Period.monthly && monthlyData.length > 1) ...[
          _buildChart(monthlyData),
          const SizedBox(height: 16),
        ],

        // Earnings list
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: LuxuryTheme.purpleLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('Earnings Breakdown', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${list.length} records', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        ...list.map(_earningRow),
      ],
    );
  }

  Widget _buildChart(Map<String, double> data) {
    final entries = data.entries.toList().reversed.take(6).toList().reversed.toList();
    final maxVal  = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Last ${entries.length} Months', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((e) {
              final ratio  = maxVal > 0 ? e.value / maxVal : 0.0;
              final isMax  = e.value == maxVal;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(_fmtShort(e.value), style: TextStyle(
                      color: isMax ? LuxuryTheme.gold : LuxuryTheme.purpleLight.withAlpha(180),
                      fontSize: 8, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: (ratio * 68).clamp(4.0, 68.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMax ? [LuxuryTheme.gold, LuxuryTheme.goldLight] : [LuxuryTheme.purple, LuxuryTheme.purpleLight],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: (isMax ? LuxuryTheme.gold : LuxuryTheme.purple).withAlpha(80), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(e.key, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 8)),
                ]),
              ));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _earningRow(AppointmentModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(40)),
      ),
      child: Row(children: [
        // Date block
        Container(
          width: 40, height: 46,
          decoration: BoxDecoration(
            color: LuxuryTheme.purple.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LuxuryTheme.purple.withAlpha(80)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('dd').format(a.date), style: const TextStyle(color: LuxuryTheme.purpleLight, fontSize: 15, fontWeight: FontWeight.w800, height: 1)),
            Text(DateFormat('MMM').format(a.date).toUpperCase(), style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 8, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.serviceName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${a.timeSlot}  •  ${a.duration} min', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
        ])),
        Text('LKR ${a.price}', style: const TextStyle(color: LuxuryTheme.gold, fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80,
      decoration: BoxDecoration(shape: BoxShape.circle, color: LuxuryTheme.gold.withAlpha(20),
          border: Border.all(color: LuxuryTheme.gold.withAlpha(60))),
      child: const Icon(Icons.payments_outlined, color: LuxuryTheme.gold, size: 36)),
    const SizedBox(height: 16),
    const Text('No earnings yet', style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    const Text('Completed jobs will appear here', style: TextStyle(color: Colors.white38, fontSize: 12)),
  ]));

  String _fmt(double v) => v >= 1000 ? NumberFormat('#,##0').format(v) : v.toStringAsFixed(0);
  String _fmtShort(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}
