import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_glamora/beautician_home.dart';
import 'admin_home.dart';
import 'user_home.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

       final data = snapshot.data!.data() as Map<String, dynamic>?;
final role = data?['role'] ?? 'user';

if (role == 'admin') return const AdminHome();
if (role == 'beautician') return const BeauticianHome();
return const UserHome(); // customer
      },
    );
  }
}

