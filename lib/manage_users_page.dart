import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  // Roles used in your system
  static const List<String> roles = ['customer', 'beautician', 'admin'];

  // Theme colors (same style as your auth pages)
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF141414);
  static const Color _gold = Color(0xFFD4AF37);

  Future<void> _updateRole(String uid, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': newRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          "Manage Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _centerText("Error: ${snapshot.error}");
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return _centerText("No users found");
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final name = (data['name'] ?? 'No name').toString();
                final email = (data['email'] ?? '').toString();
                final roleRaw = (data['role'] ?? 'customer').toString();
                final role = roles.contains(roleRaw) ? roleRaw : 'customer';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // avatar
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold.withOpacity(0.14),
                          border: Border.all(color: _gold.withOpacity(0.55)),
                        ),
                        child: const Icon(Icons.person, color: _gold),
                      ),
                      const SizedBox(width: 12),

                      // name & email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // role dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _gold.withOpacity(0.35)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: _card,
                            value: role,
                            iconEnabledColor: _gold,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            items: roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              if (val == null) return;

                              try {
                                await _updateRole(doc.id, val);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Role updated to $val ✅"),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed: $e"),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _centerText(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.8)),
        textAlign: TextAlign.center,
      ),
    );
  }
}