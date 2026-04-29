import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_services_page.dart';
import 'user_appointments_page.dart';
import 'user_profile_page.dart';
import 'user_ai_page.dart';
import 'widgets/luxury_nav_bar.dart';
import 'widgets/luxury_form_widgets.dart';

class CustomerNavPage extends StatefulWidget {
  const CustomerNavPage({super.key});

  @override
  State<CustomerNavPage> createState() => _CustomerNavPageState();
}

class _CustomerNavPageState extends State<CustomerNavPage> {
  int _selectedIndex = 0;

  static const _pages = [
    UserServicesPage(),
    UserAppointmentsPage(),
    UserAiPage(),
    UserProfilePage(),
  ];

  static const _titles = [
    'Services',
    'Appointments',
    'AI Stylist',
    'Profile',
  ];

  static const _navItems = [
    LuxuryNavItem(
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa_rounded,
      label: 'Services',
    ),
    LuxuryNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Bookings',
    ),
    LuxuryNavItem(
      icon: Icons.face_retouching_off_outlined,
      activeIcon: Icons.face_retouching_natural,
      label: 'AI Stylist',
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
