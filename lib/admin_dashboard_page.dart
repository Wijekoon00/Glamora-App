import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "Admin";
    final userUid = user?.uid ?? "No UID";

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _gold.withOpacity(0.45)),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: _gold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Admin Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "UID: $userUid",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick menu title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Menu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Menu grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: const [
                _DashboardInfoTile(
                  title: "Users",
                  subtitle: "Manage roles & accounts",
                  icon: Icons.people_alt,
                ),
                _DashboardInfoTile(
                  title: "Reports",
                  subtitle: "Analytics coming soon",
                  icon: Icons.bar_chart,
                ),
                _DashboardInfoTile(
                  title: "AI Tools",
                  subtitle: "Future AI management",
                  icon: Icons.smart_toy,
                ),
                _DashboardInfoTile(
                  title: "Settings",
                  subtitle: "System settings later",
                  icon: Icons.settings,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DashboardInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DashboardInfoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
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
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}