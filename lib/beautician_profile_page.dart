import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianProfilePage extends StatelessWidget {
  const BeauticianProfilePage({super.key});

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
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name  = data['name']  as String? ?? 'Beautician';
          final phone = data['phone'] as String? ?? '—';
          final email = user?.email   ?? '—';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildAvatar(name),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                // Beautician badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.purpleLight.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: LuxuryTheme.purpleLight.withAlpha(100)),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.spa_rounded,
                        color: LuxuryTheme.purpleLight, size: 13),
                    SizedBox(width: 5),
                    Text('Beautician',
                        style: TextStyle(
                            color: LuxuryTheme.purpleLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 28),
                _infoCard(Icons.alternate_email_rounded,
                    'Email Address', email),
                const SizedBox(height: 12),
                _infoCard(Icons.phone_outlined, 'Mobile Number', phone),
                const SizedBox(height: 12),
                _infoCard(Icons.fingerprint_rounded, 'Account ID',
                    user?.uid ?? '—',
                    mono: true),
                const SizedBox(height: 28),
                // Stats card
                _statsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'B';
    return Stack(alignment: Alignment.center, children: [
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            LuxuryTheme.purple.withAlpha(60),
            Colors.transparent,
          ]),
        ),
      ),
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: LuxuryTheme.purple.withAlpha(100),
                blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Center(child: Text(initials,
            style: const TextStyle(color: Colors.white,
                fontSize: 28, fontWeight: FontWeight.w800))),
      ),
    ]);
  }

  Widget _infoCard(IconData icon, String label, String value,
      {bool mono = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: LuxuryTheme.purple.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: LuxuryTheme.purpleLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: mono ? 11 : 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null),
                overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }

  Widget _statsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            LuxuryTheme.purple.withAlpha(80),
            LuxuryTheme.purpleDim.withAlpha(120),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: LuxuryTheme.purpleLight.withAlpha(60)),
      ),
      child: Row(children: [
        const Icon(Icons.spa_rounded,
            color: LuxuryTheme.goldLight, size: 32),
        const SizedBox(width: 14),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glamora Beautician',
                style: TextStyle(
                    color: LuxuryTheme.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            SizedBox(height: 3),
            Text('Professional beauty specialist',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withAlpha(80)),
          ),
          child: const Text('Active',
              style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
