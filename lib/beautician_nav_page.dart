import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'beautician_jobs_page.dart';
import 'beautician_completed_page.dart';
import 'beautician_profile_page.dart';

class BeauticianNavPage extends StatefulWidget {
  const BeauticianNavPage({super.key});

  @override
  State<BeauticianNavPage> createState() => _BeauticianNavPageState();
}

class _BeauticianNavPageState extends State<BeauticianNavPage> {
  int _selectedIndex = 0;

  static const _bg = Color(0xFF0B0B0B);
  static const _gold = Color(0xFFD4AF37);

  final List<Widget> _pages = const [
    BeauticianJobsPage(),
    BeauticianCompletedPage(),
    BeauticianProfilePage(),
  ];

  final List<String> _titles = const [
    "Beautician Jobs",
    "Completed Jobs",
    "Profile",
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Completed",
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