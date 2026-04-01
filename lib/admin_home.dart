import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/admin_services_page.dart';
import 'manage_users_page.dart';
import 'pages/admin_appointments_page.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Admin";

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          IconButton(
            tooltip: "Logout",
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: _gold),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HeaderCard(email: userEmail),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _DashboardTile(
                    title: "Manage Services",
                    subtitle: "Add • Edit • Delete",
                    icon: Icons.content_cut,
                    onTap: () => _go(context, const AdminServicesPage()),
                  ),
                  _DashboardTile(
                    title: "Manage Users",
                    subtitle: "Change roles",
                    icon: Icons.people_alt,
                    onTap: () => _go(context, const ManageUsersPage()),
                  ),
                  _DashboardTile(
                    title: "Appointments",
                    subtitle: "Approve • Complete",
                    icon: Icons.calendar_month,
                    onTap: () => _go(context, const AdminAppointmentsPage()),
                  ),
                  _DashboardTile(
                    title: "Reports",
                    subtitle: "Coming soon",
                    icon: Icons.bar_chart,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reports page coming soon 🙂"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String email;
  const _HeaderCard({required this.email});

  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.35)),
            ),
            child: const Icon(Icons.verified_user, color: _gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.35)),
                ),
                child: Icon(icon, color: _gold),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}