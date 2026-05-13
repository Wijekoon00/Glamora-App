import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'beautician_home_dashboard.dart';
import 'beautician_jobs_page.dart';
import 'beautician_completed_page.dart';
import 'beautician_earnings_page.dart';
import 'beautician_profile_page.dart';
import 'widgets/luxury_nav_bar.dart';
import 'widgets/luxury_form_widgets.dart';

class BeauticianNavPage extends StatefulWidget {
  const BeauticianNavPage({super.key});

  @override
  State<BeauticianNavPage> createState() => _BeauticianNavPageState();
}

class _BeauticianNavPageState extends State<BeauticianNavPage> {
  int _selectedIndex = 0;

  static const _titles = [
    'Home',
    'My Jobs',
    'Completed',
    'Earnings',
    'Profile',
  ];

  void _onNavTap(int i) => setState(() => _selectedIndex = i);

  Future<void> _logout() async => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    // Pages built here so dashboard can access _onNavTap
    final pages = [
      BeauticianHomeDashboard(onNavTap: _onNavTap),
      const BeauticianJobsPage(),
      const BeauticianCompletedPage(),
      const BeauticianEarningsPage(),
      const BeauticianProfilePage(),
    ];

    return Scaffold(
      backgroundColor: LuxuryTheme.black,
      appBar: luxuryAppBar(
        title: _titles[_selectedIndex],
        onLogout: _logout,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // Live pending badge on Jobs tab
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snap) {
          final pendingCount = snap.data?.docs.length ?? 0;

          return LuxuryNavBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            items: [
              const LuxuryNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              LuxuryNavItem(
                icon: Icons.work_outline_rounded,
                activeIcon: Icons.work_rounded,
                label: 'Jobs',
                badge: pendingCount > 0 ? pendingCount : null,
              ),
              const LuxuryNavItem(
                icon: Icons.check_circle_outline_rounded,
                activeIcon: Icons.check_circle_rounded,
                label: 'Completed',
              ),
              const LuxuryNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Earnings',
              ),
              const LuxuryNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
