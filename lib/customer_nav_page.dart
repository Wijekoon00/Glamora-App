import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_services_page.dart';
import 'user_appointments_page.dart';
import 'user_profile_page.dart';
import 'user_ai_page.dart'; // ✅ NEW

class CustomerNavPage extends StatefulWidget {
  const CustomerNavPage({super.key});

  @override
  State<CustomerNavPage> createState() => _CustomerNavPageState();
}

class _CustomerNavPageState extends State<CustomerNavPage> {
  int _selectedIndex = 0;

  static const _bg = Color(0xFF0B0B0B);
  static const _gold = Color(0xFFD4AF37);

  final List<Widget> _pages = const [
    UserServicesPage(),
    UserAppointmentsPage(),
        UserAiPage(), // ✅ NEW
    UserProfilePage(),
  ];

  final List<String> _titles = const [
    "Services",
    "My Appointments",
    "Profile",
    "AI Assistant", // ✅ NEW
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
        currentIndex: _selectedIndex,
        onTap: _onTap,
        backgroundColor: const Color(0xFF141414),
        selectedItemColor: _gold,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed, // ✅ IMPORTANT for 4 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Appointments",
          ),
                    BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy), // 🤖 AI icon
            label: "AI",
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