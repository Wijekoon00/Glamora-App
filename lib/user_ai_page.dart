import 'package:flutter/material.dart';

class UserAiPage extends StatelessWidget {
  const UserAiPage({super.key});

  static const _bg = Color(0xFF0B0B0B);
  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: const Center(
        child: Text(
          "AI Assistant 🤖\n(Coming Soon)",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}