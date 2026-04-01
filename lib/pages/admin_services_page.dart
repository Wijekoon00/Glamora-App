import 'package:flutter/material.dart';

import '../models/service_model.dart';
import '../services/service_repo.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  final repo = ServiceRepo();

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF121212);
  static const _gold = Color(0xFFD4AF37);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _card,
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          "Delete Service",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await repo.deleteService(id);
                _toast("Deleted ✅");
              } catch (e) {
                _toast("Delete failed: $e");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openServiceDialog({ServiceModel? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? "");
    final priceCtrl = TextEditingController(
      text: editing != null ? editing.price.toString() : "",
    );
    final durCtrl = TextEditingController(
      text: editing != null ? editing.duration.toString() : "",
    );
    final categoryCtrl = TextEditingController(text: editing?.category ?? "");
    final imageCtrl = TextEditingController(text: editing?.imageUrl ?? "");

    bool isActive = editing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: _card,
            title: Text(
              editing == null ? "Add Service" : "Edit Service",
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GoldTextField(
                    controller: nameCtrl,
                    hint: "Service name (e.g. Hair Cut)",
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  _GoldTextField(
                    controller: priceCtrl,
                    hint: "Price (e.g. 1500)",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _GoldTextField(
                    controller: durCtrl,
                    hint: "Duration in minutes (e.g. 30)",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _GoldTextField(
                    controller: categoryCtrl,
                    hint: "Category (hair / beard / facial)",
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  _GoldTextField(
                    controller: imageCtrl,
                    hint: "Image URL (optional)",
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    activeColor: _gold,
                    title: const Text(
                      "Active Service",
                      style: TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = num.tryParse(priceCtrl.text.trim());
                  final duration = int.tryParse(durCtrl.text.trim());
                  final category = categoryCtrl.text.trim();
                  final imageUrl = imageCtrl.text.trim();

                  if (name.isEmpty ||
                      price == null ||
                      duration == null ||
                      category.isEmpty) {
                    _toast("Please fill all required fields correctly");
                    return;
                  }

                  Navigator.pop(context);

                  try {
                    if (editing == null) {
                      await repo.addService(
                        name: name,
                        price: price,
                        duration: duration,
                        category: category,
                        imageUrl: imageUrl.isEmpty ? null : imageUrl,
                        isActive: isActive,
                      );
                      _toast("Added ✅");
                    } else {
                      await repo.updateService(
                        id: editing.id,
                        name: name,
                        price: price,
                        duration: duration,
                        category: category,
                        imageUrl: imageUrl.isEmpty ? null : imageUrl,
                        isActive: isActive,
                      );
                      _toast("Updated ✅");
                    }
                  } catch (e) {
                    _toast("Save failed: $e");
                  }
                },
                child: Text(editing == null ? "Add" : "Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.greenAccent : Colors.redAccent,
          width: 0.8,
        ),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: TextStyle(
          color: isActive ? Colors.greenAccent : Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          "Services",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Add service",
            onPressed: () => _openServiceDialog(),
            icon: const Icon(Icons.add_circle, color: _gold),
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: repo.streamServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                "No services yet.\nTap + to add.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = items[i];

              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price: ${s.price}  |  Duration: ${s.duration} mins",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Category: ${s.category}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(s.isActive),
                      ],
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: "Edit",
                        icon: const Icon(Icons.edit, color: _gold),
                        onPressed: () => _openServiceDialog(editing: s),
                      ),
                      IconButton(
                        tooltip: "Delete",
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(s.id, s.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        onPressed: () => _openServiceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _GoldTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: _gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _gold.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.4),
        ),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
      ),
    );
  }
}