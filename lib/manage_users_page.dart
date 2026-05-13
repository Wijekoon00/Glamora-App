import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterRole  = 'all'; // all | user | beautician | admin

  static const _roles = ['user', 'beautician', 'admin'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateRole(
      BuildContext ctx, String uid, String newRole) async {
    // Prevent admin from changing their own role
    final me = FirebaseAuth.instance.currentUser;
    if (me?.uid == uid) {
      _snack(ctx, "You can't change your own role", error: true);
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': newRole});
      if (!ctx.mounted) return;
      _snack(ctx, 'Role updated to $newRole');
    } catch (e) {
      if (!ctx.mounted) return;
      _snack(ctx, 'Failed: $e', error: true);
    }
  }

  Future<void> _confirmDelete(
      BuildContext ctx, String uid, String name) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me?.uid == uid) {
      _snack(ctx, "You can't delete your own account", error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Colors.redAccent.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete User',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Remove "$name" from the system?\nThis cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withAlpha(140),
                      fontSize: 13,
                      height: 1.5)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withAlpha(30)),
                      ),
                      child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB71C1C), Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.red.withAlpha(80),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .delete();
        if (!ctx.mounted) return;
        _snack(ctx, '$name removed');
      } catch (e) {
        if (!ctx.mounted) return;
        _snack(ctx, 'Delete failed: $e', error: true);
      }
    }
  }

  void _snack(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor:
          error ? Colors.redAccent : LuxuryTheme.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return LuxuryTheme.gold;
      case 'beautician': return LuxuryTheme.purpleLight;
      default:           return Colors.green;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':      return Icons.admin_panel_settings_rounded;
      case 'beautician': return Icons.spa_rounded;
      default:           return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LuxuryTheme.black,
      child: Column(children: [
        // ── Search + filter bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: LuxuryTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: LuxuryTheme.purple.withAlpha(80)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: LuxuryTheme.purpleLight,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: TextStyle(
                      color: Colors.white.withAlpha(60), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: LuxuryTheme.purpleLight.withAlpha(180),
                      size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close_rounded,
                              color: Colors.white38, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Role filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Customers', 'user'),
                const SizedBox(width: 8),
                _filterChip('Beauticians', 'beautician'),
                const SizedBox(width: 8),
                _filterChip('Admins', 'admin'),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // ── User list ────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: LuxuryTheme.purpleLight),
                );
              }

              var docs = snapshot.data!.docs;

              // Apply role filter
              if (_filterRole != 'all') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['role'] ?? 'user') == _filterRole;
                }).toList();
              }

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final email =
                      (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          color: LuxuryTheme.purpleLight.withAlpha(80),
                          size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No users match "$_searchQuery"'
                            : 'No users found',
                        style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc  = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final uid   = doc.id;
                  final name  = (data['name']  ?? 'No name').toString();
                  final email = (data['email'] ?? '').toString();
                  final phone = (data['phone'] ?? '—').toString();
                  final rawRole = (data['role'] ?? 'user').toString();
                  final role = _roles.contains(rawRole) ? rawRole : 'user';
                  final isMe =
                      FirebaseAuth.instance.currentUser?.uid == uid;
                  final roleColor = _roleColor(role);

                  return Container(
                    decoration: BoxDecoration(
                      color: LuxuryTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isMe
                              ? LuxuryTheme.gold.withAlpha(80)
                              : LuxuryTheme.purple.withAlpha(50)),
                      boxShadow: [
                        BoxShadow(
                            color: LuxuryTheme.purple.withAlpha(15),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header row ─────────────────────────────
                          Row(children: [
                            ProfileAvatarWidget(
                                name: name, uid: uid, size: 48),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w700),
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ),
                                  if (isMe)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: LuxuryTheme.gold
                                            .withAlpha(25),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: LuxuryTheme.gold
                                                .withAlpha(80)),
                                      ),
                                      child: const Text('You',
                                          style: TextStyle(
                                              color: LuxuryTheme.gold,
                                              fontSize: 9,
                                              fontWeight:
                                                  FontWeight.w800)),
                                    ),
                                ]),
                                const SizedBox(height: 3),
                                Text(email,
                                    style: TextStyle(
                                        color:
                                            Colors.white.withAlpha(120),
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                                if (phone != '—') ...[
                                  const SizedBox(height: 2),
                                  Text(phone,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withAlpha(80),
                                          fontSize: 11)),
                                ],
                              ],
                            )),
                          ]),
                          const SizedBox(height: 12),

                          // ── Role + actions row ──────────────────────
                          Row(children: [
                            // Current role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: roleColor.withAlpha(80)),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Icon(_roleIcon(role),
                                    color: roleColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  role == 'user'
                                      ? 'Customer'
                                      : role[0].toUpperCase() +
                                          role.substring(1),
                                  style: TextStyle(
                                      color: roleColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ]),
                            ),
                            const Spacer(),

                            // Change role dropdown
                            if (!isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                decoration: BoxDecoration(
                                  color: LuxuryTheme.black,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: LuxuryTheme.purple
                                          .withAlpha(80)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: role,
                                    dropdownColor: LuxuryTheme.card,
                                    iconEnabledColor:
                                        LuxuryTheme.purpleLight,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    isDense: true,
                                    items: _roles.map((r) {
                                      final rc = _roleColor(r);
                                      return DropdownMenuItem(
                                        value: r,
                                        child: Row(children: [
                                          Icon(_roleIcon(r),
                                              color: rc, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            r == 'user'
                                                ? 'Customer'
                                                : r[0].toUpperCase() +
                                                    r.substring(1),
                                            style: TextStyle(
                                                color: rc,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ]),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null && val != role) {
                                        _updateRole(context, uid, val);
                                      }
                                    },
                                  ),
                                ),
                              ),

                            const SizedBox(width: 8),

                            // Delete button
                            if (!isMe)
                              GestureDetector(
                                onTap: () => _confirmDelete(
                                    context, uid, name),
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.redAccent
                                            .withAlpha(80)),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 16),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filterRole == value;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight])
              : null,
          color: active ? null : LuxuryTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? LuxuryTheme.purpleLight
                : LuxuryTheme.purple.withAlpha(60),
          ),
          boxShadow: active
              ? [BoxShadow(
                  color: LuxuryTheme.purple.withAlpha(80),
                  blurRadius: 8)]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500)),
      ),
    );
  }
}
