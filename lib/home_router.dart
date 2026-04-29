import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_nav_page.dart';
import 'beautician_nav_page.dart';
import 'customer_nav_page.dart';
import 'widgets/luxury_form_widgets.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: LuxuryTheme.black,
        body: Center(
          child: Text('User not found',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: LuxuryTheme.black,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryTheme.card,
                      border: Border.all(
                          color: LuxuryTheme.purpleLight.withAlpha(150),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: LuxuryTheme.purple.withAlpha(80),
                            blurRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.spa_rounded,
                        color: LuxuryTheme.goldLight, size: 30),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color: LuxuryTheme.purpleLight,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Loading your experience...',
                      style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 13)),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: LuxuryTheme.black,
            body: Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white54)),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'user';

        if (role == 'admin')      return const AdminNavPage();
        if (role == 'beautician') return const BeauticianNavPage();
        return const CustomerNavPage();
      },
    );
  }
}