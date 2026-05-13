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

class _BeauticianJobsPageState extends State<BeauticianJobsPage>
    with SingleTickerProviderStateMixin {
  final _repo = AppointmentRepo();
  bool _loading = false;

  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: LuxuryTheme.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _updateStatus(String id, String status) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _repo.updateStatus(id, status);
      final msg = status == 'approved'
          ? 'Appointment approved ✅'
          : status == 'cancelled'
              ? 'Appointment cancelled ❌'
              : 'Marked as completed ✅';
      _toast(msg);
    } catch (_) {
      _toast('Update failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LuxuryTheme.black,
      child: Column(children: [
        // ── Filter tab bar ───────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            border: Border(bottom: BorderSide(color: LuxuryTheme.purpleLight.withAlpha(40), width: 1)),
          ),
          child: TabBar(
            controller: _tab,
            indicatorColor: LuxuryTheme.purpleLight,
            indicatorWeight: 2,
            labelColor: LuxuryTheme.purpleLight,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.hourglass_empty_rounded, size: 15), text: 'Pending'),
              Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 15), text: 'Approved'),
              Tab(icon: Icon(Icons.list_rounded, size: 15), text: 'All Active'),
            ],
          ),
        ),

        // ── Job lists ────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<AppointmentModel>>(
            stream: _repo.getAllAppointments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: LuxuryTheme.purpleLight));
              }

              final all = snapshot.data!;
              // Sort by date then time slot
              all.sort((a, b) {
                final dateCmp = a.date.compareTo(b.date);
                if (dateCmp != 0) return dateCmp;
                return a.timeSlot.compareTo(b.timeSlot);
              });

              final pending  = all.where((a) => a.status == 'pending').toList();
              final approved = all.where((a) => a.status == 'approved').toList();
              final active   = all.where((a) => a.status == 'pending' || a.status == 'approved').toList();

              return TabBarView(
                controller: _tab,
                children: [
                  _JobList(jobs: pending,  onAction: _updateStatus, loading: _loading, emptyMsg: 'No pending appointments'),
                  _JobList(jobs: approved, onAction: _updateStatus, loading: _loading, emptyMsg: 'No approved appointments'),
                  _JobList(jobs: active,   onAction: _updateStatus, loading: _loading, emptyMsg: 'No active appointments'),
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
class _JobList extends StatelessWidget {
  final List<AppointmentModel> jobs;
  final Future<void> Function(String, String) onAction;
  final bool loading;
  final String emptyMsg;

  const _JobList({
    required this.jobs,
    required this.onAction,
    required this.loading,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: LuxuryTheme.purple.withAlpha(30),
              border: Border.all(color: LuxuryTheme.purple.withAlpha(60))),
          child: const Icon(Icons.work_outline_rounded, color: LuxuryTheme.purpleLight, size: 32)),
        const SizedBox(height: 14),
        Text(emptyMsg, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _JobCard(appointment: jobs[i], onAction: onAction, loading: loading),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(String, String) onAction;
  final bool loading;

  const _JobCard({required this.appointment, required this.onAction, required this.loading});

  Color get _statusColor {
    switch (appointment.status) {
      case 'approved':  return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.redAccent;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final sc = _statusColor;

    // Check if appointment is today
    final now = DateTime.now();
    final isToday = a.date.year == now.year && a.date.month == now.month && a.date.day == now.day;

    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isToday ? LuxuryTheme.gold.withAlpha(80) : LuxuryTheme.purple.withAlpha(60)),
        boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(25), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: sc.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(a.status == 'approved' ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded,
                  color: sc, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.serviceName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(a.userName, style: TextStyle(color: LuxuryTheme.purpleLight.withAlpha(200), fontSize: 12)),
            ])),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: LuxuryTheme.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LuxuryTheme.gold.withAlpha(80)),
                ),
                child: const Text('TODAY', style: TextStyle(color: LuxuryTheme.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
          ]),
          const SizedBox(height: 12),

          // Details grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LuxuryTheme.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LuxuryTheme.purple.withAlpha(30)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _detail(Icons.calendar_today_rounded, DateFormat('MMM dd, yyyy').format(a.date)),
                const SizedBox(height: 6),
                _detail(Icons.access_time_rounded, a.timeSlot),
              ])),
              Container(width: 1, height: 40, color: LuxuryTheme.purple.withAlpha(40), margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _detail(Icons.payments_outlined, '${a.price} LKR'),
                const SizedBox(height: 6),
                _detail(Icons.timer_outlined, '${a.duration} mins'),
              ])),
            ]),
          ),
          const SizedBox(height: 12),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: sc.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sc),
            ),
            child: Text(a.status.toUpperCase(), style: TextStyle(color: sc, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),

          // Action buttons
          if (a.status == 'pending')
            Row(children: [
              Expanded(child: _btn('Approve', [Colors.green.shade700, Colors.green], loading ? null : () => onAction(a.id, 'approved'))),
              const SizedBox(width: 10),
              Expanded(child: _btn('Cancel', [Colors.red.shade800, Colors.redAccent], loading ? null : () => onAction(a.id, 'cancelled'))),
            ])
          else if (a.status == 'approved')
            _btn('Mark Completed', [LuxuryTheme.purple, LuxuryTheme.purpleLight],
                loading ? null : () => onAction(a.id, 'completed'),
                fullWidth: true, glow: LuxuryTheme.purple),
        ]),
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: LuxuryTheme.purpleLight),
    const SizedBox(width: 5),
    Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _btn(String label, List<Color> colors, VoidCallback? onTap, {bool fullWidth = false, Color? glow}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
            boxShadow: glow != null ? [BoxShadow(color: glow.withAlpha(100), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}
