import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/luxury_form_widgets.dart';
import 'widgets/profile_avatar_widget.dart';

class BeauticianProfilePage extends StatefulWidget {
  const BeauticianProfilePage({super.key});

  @override
  State<BeauticianProfilePage> createState() => _BeauticianProfilePageState();
}

class _BeauticianProfilePageState extends State<BeauticianProfilePage> {
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
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Name cannot be empty', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':  name,
        'phone': phone,
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
          final name  = data['name']  as String? ?? 'Beautician';
          final phone = data['phone'] as String? ?? '';
          final email = user?.email ?? '—';

          // Pre-fill controllers when not editing
          if (!_editing) {
            _nameCtrl.text  = name;
            _phoneCtrl.text = phone;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const SizedBox(height: 10),

              // Avatar
              ProfileAvatarWidget(name: name, uid: user?.uid ?? '', size: 90),
              const SizedBox(height: 16),

              // Name
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: LuxuryTheme.purpleLight.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(100)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.spa_rounded, color: LuxuryTheme.purpleLight, size: 13),
                  SizedBox(width: 5),
                  Text('Beautician', style: TextStyle(color: LuxuryTheme.purpleLight, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
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

              // Status card
              Container(
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
                  const Icon(Icons.spa_rounded, color: LuxuryTheme.goldLight, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Glamora Beautician', style: TextStyle(color: LuxuryTheme.goldLight, fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 3),
                    Text('Professional beauty specialist', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withAlpha(80)),
                    ),
                    child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
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
}
