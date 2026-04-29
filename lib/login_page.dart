import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'widgets/luxury_form_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: LuxuryTheme.purpleDim,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Login failed');
    } catch (e) {
      _snack('Login failed: $e');
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
          // ── Decorative background blobs ──────────────────────────────
          Positioned(top: -80, right: -60,
              child: _blob(220, LuxuryTheme.purple.withAlpha(40))),
          Positioned(bottom: -100, left: -80,
              child: _blob(280, LuxuryTheme.purpleLight.withAlpha(25))),
          Positioned(top: 180, left: -40,
              child: _blob(140, LuxuryTheme.gold.withAlpha(15))),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(children: [
                        _buildLogo(),
                        const SizedBox(height: 36),
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildRegisterLink(),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ─────────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(children: [
      // Glow ring + icon
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            LuxuryTheme.purple.withAlpha(60),
            Colors.transparent,
          ]),
        ),
        child: Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxuryTheme.card,
              border: Border.all(
                  color: LuxuryTheme.purpleLight.withAlpha(180), width: 1.5),
              boxShadow: [
                BoxShadow(color: LuxuryTheme.purple.withAlpha(80),
                    blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.spa_rounded,
                color: LuxuryTheme.goldLight, size: 36),
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Brand name — gradient text
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [LuxuryTheme.goldLight, LuxuryTheme.gold,
            LuxuryTheme.purpleLight],
          stops: [0.0, 0.5, 1.0],
        ).createShader(b),
        child: const Text(
          'GLAMORA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'LUXURY SALON & SPA',
        style: TextStyle(
          color: LuxuryTheme.purpleLight.withAlpha(200),
          fontSize: 11,
          letterSpacing: 4,
        ),
      ),
      const SizedBox(height: 12),

      // Decorative divider
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _divLine(reverse: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.diamond_outlined,
              color: LuxuryTheme.gold.withAlpha(160), size: 14),
        ),
        _divLine(),
      ]),
    ]);
  }

  // ── Form card ────────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: LuxuryTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: LuxuryTheme.purpleLight.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: LuxuryTheme.purple.withAlpha(40),
            blurRadius: 40, spreadRadius: -5,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Welcome Back',
            style: TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your account',
            style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13),
          ),
          const SizedBox(height: 28),

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
          const SizedBox(height: 16),

          LuxuryField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
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
          const SizedBox(height: 28),

          LuxuryButton(
            label: 'Sign In',
            loading: _loading,
            onTap: _login,
          ),
        ]),
      ),
    );
  }

  // ── Register link ─────────────────────────────────────────────────────────────
  Widget _buildRegisterLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('New to Glamora? ',
          style: TextStyle(
              color: Colors.white.withAlpha(120), fontSize: 13)),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RegisterPage())),
        child: const Text(
          'Create Account',
          style: TextStyle(color: LuxuryTheme.purpleLight,
              fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _divLine({bool reverse = false}) => Container(
    width: 50, height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: reverse
            ? [LuxuryTheme.gold.withAlpha(120), Colors.transparent]
            : [Colors.transparent, LuxuryTheme.gold.withAlpha(120)],
      ),
    ),
  );
}
