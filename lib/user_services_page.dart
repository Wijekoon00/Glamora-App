import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/service_model.dart';
import 'models/appointment_model.dart';
import 'services/service_repo.dart';
import 'services/appointment_repo.dart';

class UserServicesPage extends StatefulWidget {
  const UserServicesPage({super.key});

  @override
  State<UserServicesPage> createState() => _UserServicesPageState();
}

class _UserServicesPageState extends State<UserServicesPage> {
  final serviceRepo = ServiceRepo();
  final appointmentRepo = AppointmentRepo();

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
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

  Future<void> _createBooking({
    required String serviceId,
    required String serviceName,
    required num price,
    required int duration,
    required DateTime selectedDate,
    required String selectedTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _toast("User not logged in");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName = (userData['name'] ?? 'Unknown User').toString();

      final appointment = AppointmentModel(
        id: '',
        userId: user.uid,
        userName: userName,
        serviceId: serviceId,
        serviceName: serviceName,
        price: price,
        duration: duration,
        date: selectedDate,
        timeSlot: selectedTime,
        status: 'pending',
      );

      await appointmentRepo.bookAppointment(appointment);

      _toast("Appointment booked successfully ✅");
    } catch (e) {
      _toast("Booking failed: $e");
    }
  }

  Future<void> _bookService(ServiceModel service) async {
    if (!service.isActive) {
      _toast("This service is currently unavailable");
      return;
    }

    DateTime? selectedDate;
    String? selectedTime;
    bool isSaving = false;

    final timeSlots = [
      "09:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "02:00 PM",
      "03:00 PM",
      "04:00 PM",
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: _card,
            title: Text(
              "Book ${service.name}",
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: DateTime.now(),
                      );

                      if (date != null) {
                        setStateDialog(() => selectedDate = date);
                      }
                    },
                    child: Text(
                      selectedDate == null
                          ? "Select Date"
                          : DateFormat('yyyy-MM-dd').format(selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  dropdownColor: _card,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _gold.withOpacity(0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _gold),
                    ),
                  ),
                  hint: const Text(
                    "Select Time",
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: timeSlots
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setStateDialog(() => selectedTime = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
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
                onPressed: isSaving
                    ? null
                    : () async {
                        if (selectedDate == null || selectedTime == null) {
                          _toast("Select date and time");
                          return;
                        }

                        setStateDialog(() => isSaving = true);

                        await _createBooking(
                          serviceId: service.id,
                          serviceName: service.name,
                          price: service.price,
                          duration: service.duration,
                          selectedDate: selectedDate!,
                          selectedTime: selectedTime!,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Book"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Text(
        isActive ? "Available" : "Unavailable",
        style: TextStyle(
          color: isActive ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: StreamBuilder<List<ServiceModel>>(
        stream: serviceRepo.streamServices(),
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

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return const Center(
              child: Text(
                "No services available",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final s = services[index];

              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Price: ${s.price} LKR",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Duration: ${s.duration} mins",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Category: ${s.category}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(s.isActive),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                s.isActive ? _gold : Colors.grey.shade700,
                            foregroundColor:
                                s.isActive ? Colors.black : Colors.white70,
                          ),
                          onPressed: s.isActive ? () => _bookService(s) : null,
                          child: Text(
                            s.isActive ? "Book Now" : "Unavailable",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}