import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_main_dashboard.dart';
import 'pages/admin_services_page.dart';
import 'pages/admin_appointments_page.dart';
import 'manage_users_page.dart';
import 'admin_profile_page.dart';
import 'widgets/luxury_nav_bar.dart';
import 'widgets/luxury_form_widgets.dart';

class AdminNavPage extends StatefulWidget {
  const AdminNavPage({super.key});

  @override
  State<AdminNavPage> createState() => _AdminNavPageState();
}

class _AdminNavPageState extends State<AdminNavPage> {
  int _selectedIndex = 0;

  static const _titles = [
    'Dashboard',
    'Services',
    'Appointments',
    'Users',
    'Profile',
  ];

  static const _navItems = [
    LuxuryNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    LuxuryNavItem(
      icon: Icons.content_cut_outlined,
      activeIcon: Icons.content_cut_rounded,
      label: 'Services',
    ),
    LuxuryNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Bookings',
    ),
    LuxuryNavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Users',
    ),
    LuxuryNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  Future<void> _logout() async =>
      FirebaseAuth.instance.signOut();

  void _onNavTap(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    // Pages built here so dashboard can access _onNavTap
    final pages = [
      AdminMainDashboard(onNavTap: _onNavTap),
      const AdminServicesPage(),
      const AdminAppointmentsPage(),
      const ManageUsersPage(),
      const AdminProfilePage(),
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
      bottomNavigationBar: LuxuryNavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
