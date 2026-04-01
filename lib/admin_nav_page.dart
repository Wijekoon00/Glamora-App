import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_glamora/test_page.dart';

import 'admin_dashboard_page.dart';
import 'manage_users_page.dart';
import 'pages/admin_services_page.dart';
import 'pages/admin_appointments_page.dart';

class AdminNavPage extends StatefulWidget {
  const AdminNavPage({super.key});

  @override
  State<AdminNavPage> createState() => _AdminNavPageState();
}

class _AdminNavPageState extends State<AdminNavPage> {
  int _selectedIndex = 0;

  static const _bg = Color(0xFF0B0B0B);
  static const _gold = Color(0xFFD4AF37);

  final List<Widget> _pages = const [
    TestPage(),
    AdminServicesPage(),
    AdminAppointmentsPage(),
    AdminDashboardPage(),
  ];

  final List<String> _titles = const [
    "Admin Dashboard",
    "Services",
    "Appointments",
    "Users",
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTap,
        backgroundColor: const Color(0xFF141414),
        selectedItemColor: _gold,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}