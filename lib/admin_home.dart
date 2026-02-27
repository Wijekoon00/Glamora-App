import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_users_page.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: _gold),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _GoldCardButton(
                title: "Manage Users & Roles",
                subtitle: "Set customer / beautician / admin",
                icon: Icons.manage_accounts,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageUsersPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // You can add more admin cards later:
              _GoldCardButton(
                title: "Services",
                subtitle: "Add / edit / delete services",
                icon: Icons.design_services,
                onTap: () {
                  // Later: open your services CRUD page
                },
              ),
              const SizedBox(height: 12),

              _GoldCardButton(
                title: "Appointments",
                subtitle: "View & manage bookings",
                icon: Icons.calendar_month,
                onTap: () {
                  // Later: open appointments page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldCardButton extends StatelessWidget {
  const _GoldCardButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withOpacity(0.14),
                border: Border.all(color: _gold.withOpacity(0.55)),
              ),
              child: Icon(icon, color: _gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _gold.withOpacity(0.9)),
          ],
        ),
      ),
    );
  }
}