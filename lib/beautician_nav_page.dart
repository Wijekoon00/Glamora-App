import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'beautician_jobs_page.dart';
import 'beautician_completed_page.dart';
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

  static const _pages = [
    BeauticianJobsPage(),
    BeauticianCompletedPage(),
    BeauticianProfilePage(),
  ];

  static const _titles = [
    'My Jobs',
    'Completed',
    'Profile',
  ];

  static const _navItems = [
    LuxuryNavItem(
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: 'Jobs',
    ),
    LuxuryNavItem(
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
      label: 'Completed',
    ),
    LuxuryNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  Future<void> _logout() async =>
      FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.black,
      appBar: luxuryAppBar(
        title: _titles[_selectedIndex],
        onLogout: _logout,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: LuxuryNavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
