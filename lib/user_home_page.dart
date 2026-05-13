import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/appointment_model.dart';
import 'models/service_model.dart';
import 'services/appointment_repo.dart';
import 'services/service_repo.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

class UserHomePage extends StatelessWidget {
  final void Function(int) onNavTap;
  const UserHomePage({super.key, required this.onNavTap});

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
        builder: (context, userSnap) {
          final data = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] as String? ?? 'Guest';

          return StreamBuilder<List<AppointmentModel>>(
            stream: AppointmentRepo().getUserAppointments(user?.uid ?? ''),
            builder: (context, apptSnap) {
              final all = apptSnap.data ?? [];
              final upcoming = all
                  .where((a) => a.status == 'pending' || a.status == 'approved')
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
              final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;
              final lastCompleted = all
                  .where((a) => a.status == 'completed')
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // ── Welcome ──────────────────────────────────────────
                  _buildWelcome(name, user?.uid ?? ''),
                  const SizedBox(height: 20),

                  // ── Next appointment ─────────────────────────────────
                  _sectionLabel('Next Appointment'),
                  const SizedBox(height: 10),
                  nextAppt != null
                      ? _buildNextApptCard(nextAppt)
                      : _buildNoAppt(context),
                  const SizedBox(height: 20),

                  // ── Quick actions ────────────────────────────────────
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _quickAction(
                      icon: Icons.spa_rounded,
                      label: 'Book Service',
                      sub: 'Browse & book',
                      color: LuxuryTheme.purpleLight,
                      onTap: () => onNavTap(1),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _quickAction(
                      icon: Icons.calendar_month_rounded,
                      label: 'My Bookings',
                      sub: '${upcoming.length} upcoming',
                      color: const Color(0xFF64B5F6),
                      onTap: () => onNavTap(2),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _quickAction(
                      icon: Icons.face_retouching_natural,
                      label: 'AI Stylist',
                      sub: 'Get styled',
                      color: LuxuryTheme.gold,
                      onTap: () => onNavTap(4),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // ── Last service / rebook ────────────────────────────
                  if (lastCompleted.isNotEmpty) ...[
                    _sectionLabel('Book Again'),
                    const SizedBox(height: 10),
                    _buildRecentServiceCard(context, lastCompleted.first),
                    const SizedBox(height: 20),
                  ],

                  // ── Featured services ────────────────────────────────
                  _sectionLabel('Featured Services'),
                  const SizedBox(height: 10),
                  _buildFeaturedServices(context),
                ],
              );
            },
          );
        },
      ),
    );
  }

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
          Text(greeting, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: LuxuryTheme.gold.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LuxuryTheme.gold.withAlpha(80)),
            ),
            child: const Text('Glamora Member', style: TextStyle(color: LuxuryTheme.gold, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(DateFormat('EEE').format(DateTime.now()), style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
          Text(DateFormat('d MMM').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Widget _buildNextApptCard(AppointmentModel a) {
    final statusColor = a.status == 'approved' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withAlpha(80)),
        boxShadow: [BoxShadow(color: statusColor.withAlpha(30), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 60,
          decoration: BoxDecoration(
            color: LuxuryTheme.purple.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LuxuryTheme.purple.withAlpha(80)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('dd').format(a.date), style: const TextStyle(color: LuxuryTheme.purpleLight, fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
            Text(DateFormat('MMM').format(a.date).toUpperCase(), style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.serviceName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time_rounded, color: Colors.white.withAlpha(100), size: 12),
            const SizedBox(width: 4),
            Text(a.timeSlot, style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12)),
            const SizedBox(width: 10),
            Icon(Icons.payments_outlined, color: Colors.white.withAlpha(100), size: 12),
            const SizedBox(width: 4),
            Text('LKR ${a.price}', style: const TextStyle(color: LuxuryTheme.gold, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Text(a.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ]),
    );
  }

  Widget _buildNoAppt(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: LuxuryTheme.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
    ),
    child: Row(children: [
      Icon(Icons.event_available_rounded, color: LuxuryTheme.purpleLight.withAlpha(120), size: 32),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('No upcoming appointments', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('Book a service to get started', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12)),
      ])),
    ]),
  );

  Widget _buildRecentServiceCard(BuildContext context, AppointmentModel a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuxuryTheme.gold.withAlpha(60)),
        gradient: LinearGradient(
          colors: [LuxuryTheme.purpleDim.withAlpha(60), LuxuryTheme.card],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: LuxuryTheme.gold.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.replay_rounded, color: LuxuryTheme.gold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Last: ${a.serviceName}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('LKR ${a.price}  •  ${a.duration} min', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12)),
        ])),
        GestureDetector(
          onTap: () => onNavTap(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Text('Book Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildFeaturedServices(BuildContext context) {
    return StreamBuilder<List<ServiceModel>>(
      stream: ServiceRepo().streamServices(),
      builder: (context, snap) {
        final services = (snap.data ?? []).where((s) => s.isActive).take(3).toList();
        if (services.isEmpty) return const SizedBox.shrink();
        return Column(
          children: services.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LuxuryTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: LuxuryTheme.purple.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.spa_rounded, color: LuxuryTheme.purpleLight, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Text('LKR ${s.price}  •  ${s.duration} min', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12)),
              ])),
              GestureDetector(
                onTap: () => onNavTap(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ]),
          )).toList(),
        );
      },
    );
  }

  Widget _quickAction({required IconData icon, required String label, required String sub, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: LuxuryTheme.purpleLight, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}
