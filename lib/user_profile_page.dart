import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/luxury_form_widgets.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

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
          final name  = data['name']  as String? ?? 'Guest';
          final phone = data['phone'] as String? ?? '—';
          final email = user?.email   ?? '—';
          final role  = data['role']  as String? ?? 'user';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar
                _buildAvatar(name),
                const SizedBox(height: 20),
                // Name + role badge
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                _roleBadge(role),
                const SizedBox(height: 28),
                // Info cards
                _infoCard(Icons.alternate_email_rounded,
                    'Email Address', email),
                const SizedBox(height: 12),
                _infoCard(Icons.phone_outlined,
                    'Mobile Number', phone),
                const SizedBox(height: 12),
                _infoCard(Icons.fingerprint_rounded,
                    'Account ID',
                    user?.uid ?? '—',
                    mono: true),
                const SizedBox(height: 28),
                // Divider
                Row(children: [
                  Expanded(child: Divider(
                      color: LuxuryTheme.purple.withAlpha(60))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.diamond_outlined,
                        color: LuxuryTheme.gold.withAlpha(120), size: 14),
                  ),
                  Expanded(child: Divider(
                      color: LuxuryTheme.purple.withAlpha(60))),
                ]),
                const SizedBox(height: 20),
                // Membership card
                _membershipCard(),
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
        : 'G';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
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
        // Avatar circle
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
              BoxShadow(
                color: LuxuryTheme.purple.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    final label = role == 'admin'
        ? 'Administrator'
        : role == 'beautician'
            ? 'Beautician'
            : 'Member';
    final color = role == 'admin'
        ? LuxuryTheme.gold
        : LuxuryTheme.purpleLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_rounded, color: color, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
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
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: mono ? 11 : 14,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )),
      ]),
    );
  }

  Widget _membershipCard() {
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
        const Icon(Icons.diamond_rounded,
            color: LuxuryTheme.goldLight, size: 32),
        const SizedBox(width: 14),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glamora Member',
                style: TextStyle(
                    color: LuxuryTheme.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            SizedBox(height: 3),
            Text('Enjoy exclusive salon services',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: LuxuryTheme.gold.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: LuxuryTheme.gold.withAlpha(80)),
          ),
          child: const Text('Active',
              style: TextStyle(
                  color: LuxuryTheme.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
