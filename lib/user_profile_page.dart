import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'services/appointment_repo.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _editing = false;
  bool _saving  = false;

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String uid) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack('Name cannot be empty', error: true); return; }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':  name,
        'phone': _phoneCtrl.text.trim(),
      });
      setState(() { _editing = false; _saving = false; });
      _snack('Profile updated ✅');
    } catch (e) {
      setState(() => _saving = false);
      _snack('Save failed: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? Colors.redAccent : LuxuryTheme.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final data  = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name  = data['name']  as String? ?? 'Guest';
          final phone = data['phone'] as String? ?? '';
          final email = user?.email ?? '—';
          final role  = data['role']  as String? ?? 'user';
          final createdAt = data['createdAt'] != null
              ? (data['createdAt'] as dynamic).toDate() as DateTime
              : null;

          if (!_editing) {
            _nameCtrl.text  = name;
            _phoneCtrl.text = phone;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const SizedBox(height: 10),
              ProfileAvatarWidget(name: name, uid: user?.uid ?? '', size: 90),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              const SizedBox(height: 8),
              _roleBadge(role),
              const SizedBox(height: 28),

              // ── Edit / View mode ──────────────────────────────────────
              if (_editing) ...[
                _editField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _editField(_phoneCtrl, 'Mobile Number', Icons.phone_outlined, keyboard: TextInputType.phone),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _editing = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: GestureDetector(
                    onTap: _saving ? null : () => _saveProfile(user?.uid ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight]),
                        boxShadow: [BoxShadow(color: LuxuryTheme.purple.withAlpha(100), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  )),
                ]),
              ] else ...[
                _infoCard(Icons.alternate_email_rounded, 'Email Address', email),
                const SizedBox(height: 12),
                _infoCard(Icons.phone_outlined, 'Mobile Number', phone.isEmpty ? '—' : phone),
                const SizedBox(height: 12),
                _infoCard(Icons.fingerprint_rounded, 'Account ID', user?.uid ?? '—', mono: true),
                if (createdAt != null) ...[
                  const SizedBox(height: 12),
                  _infoCard(Icons.calendar_today_rounded, 'Member Since', DateFormat('MMMM d, yyyy').format(createdAt)),
                ],
                const SizedBox(height: 20),

                // Edit button
                GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(150)),
                      color: LuxuryTheme.purple.withAlpha(20),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit_rounded, color: LuxuryTheme.purpleLight, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Profile', style: TextStyle(color: LuxuryTheme.purpleLight, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Stats from history ────────────────────────────────────
              _buildStatsFromHistory(user?.uid ?? ''),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: LuxuryTheme.purple.withAlpha(60))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.diamond_outlined, color: LuxuryTheme.gold.withAlpha(120), size: 14),
                ),
                Expanded(child: Divider(color: LuxuryTheme.purple.withAlpha(60))),
              ]),
              const SizedBox(height: 20),

              // Membership card
              _membershipCard(),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildStatsFromHistory(String uid) {
    return StreamBuilder(
      stream: AppointmentRepo().getUserAppointments(uid),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final completed = all.where((a) => a.status == 'completed').toList();
        final totalSpent = completed.fold<double>(0, (s, a) => s + a.price.toDouble());
        final visits = completed.length;

        return Row(children: [
          Expanded(child: _miniStat('Total Visits', '$visits', Icons.event_available_rounded, LuxuryTheme.purpleLight)),
          const SizedBox(width: 10),
          Expanded(child: _miniStat('Total Spent', 'LKR ${_fmt(totalSpent)}', Icons.payments_rounded, LuxuryTheme.gold)),
        ]);
      },
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: LuxuryTheme.purpleLight,
        decoration: InputDecoration(
          prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(icon, color: LuxuryTheme.purpleLight.withAlpha(200), size: 18)),
          filled: true,
          fillColor: const Color(0xFF0A0A14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LuxuryTheme.purple.withAlpha(80))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LuxuryTheme.purpleLight, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _roleBadge(String role) {
    final label = role == 'admin' ? 'Administrator' : role == 'beautician' ? 'Beautician' : 'Member';
    final color = role == 'admin' ? LuxuryTheme.gold : LuxuryTheme.purpleLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_rounded, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, {bool mono = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxuryTheme.purple.withAlpha(50)),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: LuxuryTheme.purple.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: LuxuryTheme.purpleLight, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: Colors.white, fontSize: mono ? 11 : 14, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _membershipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [LuxuryTheme.purple.withAlpha(80), LuxuryTheme.purpleDim.withAlpha(120)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(60)),
      ),
      child: Row(children: [
        const Icon(Icons.diamond_rounded, color: LuxuryTheme.goldLight, size: 32),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Glamora Member', style: TextStyle(color: LuxuryTheme.goldLight, fontWeight: FontWeight.w800, fontSize: 15)),
          SizedBox(height: 3),
          Text('Enjoy exclusive salon services', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: LuxuryTheme.gold.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LuxuryTheme.gold.withAlpha(80)),
          ),
          child: const Text('Active', style: TextStyle(color: LuxuryTheme.gold, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  String _fmt(double v) => v >= 1000 ? NumberFormat('#,##0').format(v) : v.toStringAsFixed(0);
}
