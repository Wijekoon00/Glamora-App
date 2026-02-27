import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeauticianHome extends StatelessWidget {
  const BeauticianHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beautician Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: const Center(
        child: Text("Welcome Beautician 💇‍♀️"),
      ),
    );
  }
}