import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome User 👤",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}