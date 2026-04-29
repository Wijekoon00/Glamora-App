import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/luxury_form_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscure        = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  bool _agreed         = false;

  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? LuxuryTheme.purpleDim : LuxuryTheme.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) {
      _snack('Please agree to the terms to continue');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name':      _nameCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'role':      'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _snack('Account created successfully!', error: false);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Registration failed');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.black,
      body: Stack(
        children: [
          // ── Background blobs ─────────────────────────────────────────
          Positioned(top: -60, left: -80,
              child: _blob(200, LuxuryTheme.purple.withAlpha(35))),
          Positioned(bottom: -80, right: -60,
              child: _blob(240, LuxuryTheme.purpleLight.withAlpha(20))),
          Positioned(top: 300, right: -30,
              child: _blob(120, LuxuryTheme.gold.withAlpha(12))),

          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildFormCard(),
                          const SizedBox(height: 20),
                          _buildLoginLink(),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: LuxuryTheme.card,
              shape: BoxShape.circle,
              border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(80)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 16),
          ),
        ),
        const Spacer(),
        Row(children: [
          _stepDot(active: true),
          const SizedBox(width: 4),
          _stepDot(active: false),
        ]),
        const Spacer(),
        const SizedBox(width: 40),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LuxuryTheme.card,
          border: Border.all(
              color: LuxuryTheme.purpleLight.withAlpha(150), width: 1.5),
          boxShadow: [
            BoxShadow(color: LuxuryTheme.purple.withAlpha(70),
                blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.person_add_alt_1_rounded,
            color: LuxuryTheme.goldLight, size: 30),
      ),
      const SizedBox(height: 16),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [LuxuryTheme.goldLight, LuxuryTheme.gold,
            LuxuryTheme.purpleLight],
          stops: [0.0, 0.5, 1.0],
        ).createShader(b),
        child: const Text(
          'Join Glamora',
          style: TextStyle(color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Create your luxury salon account',
        style: TextStyle(
            color: Colors.white.withAlpha(110), fontSize: 13),
      ),
    ]);
  }

  // ── Form card ─────────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: LuxuryTheme.purpleLight.withAlpha(55), width: 1),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(35),
            blurRadius: 40, spreadRadius: -5,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(children: [
          _sectionLabel('Personal Information'),
          const SizedBox(height: 14),

          LuxuryField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),

          LuxuryField(
            controller: _phoneCtrl,
            label: 'Mobile Number',
            hint: '+94 7X XXX XXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (v.trim().length < 9) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 22),

          _sectionLabel('Account Details'),
          const SizedBox(height: 14),

          LuxuryField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'your@email.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),

          LuxuryField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Min. 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: LuxuryTheme.purpleLight.withAlpha(180), size: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),

          LuxuryField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: LuxuryTheme.purpleLight.withAlpha(180), size: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Terms checkbox
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: _agreed
                        ? LuxuryTheme.purple : Colors.transparent,
                    border: Border.all(
                      color: _agreed
                          ? LuxuryTheme.purpleLight : Colors.white30,
                      width: 1.5,
                    ),
                  ),
                  child: _agreed
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(
                    style: TextStyle(
                        color: Colors.white.withAlpha(130), fontSize: 12),
                    children: const [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                            color: LuxuryTheme.purpleLight,
                            fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                            color: LuxuryTheme.purpleLight,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          LuxuryButton(
            label: 'Create Account',
            loading: _loading,
            onTap: _register,
          ),
        ]),
      ),
    );
  }

  // ── Login link ────────────────────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account? ',
          style: TextStyle(
              color: Colors.white.withAlpha(120), fontSize: 13)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text(
          'Sign In',
          style: TextStyle(color: LuxuryTheme.purpleLight,
              fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Row(children: [
    Container(
      width: 3, height: 14,
      decoration: BoxDecoration(
        color: LuxuryTheme.purpleLight,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(
      color: Colors.white.withAlpha(160),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    )),
  ]);

  Widget _stepDot({required bool active}) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: active ? 20 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: active ? LuxuryTheme.purpleLight : Colors.white24,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
