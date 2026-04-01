import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/service_model.dart';
import 'models/appointment_model.dart';
import 'services/service_repo.dart';
import 'services/appointment_repo.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _bookService(ServiceModel service) async {
    DateTime? selectedDate;
    String? selectedTime;

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
                ElevatedButton(
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
                        (t) => DropdownMenuItem(
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
                  if (selectedDate == null || selectedTime == null) {
                    _toast("Select date and time");
                    return;
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    _toast("User not found");
                    return;
                  }

                  final appointment = AppointmentModel(
                    id: '',
                    userId: user.uid,
                    userName: user.email ?? "User",
                    serviceId: service.id,
                    serviceName: service.name,
                    price: service.price,
                    duration: service.duration,
                    date: selectedDate!,
                    timeSlot: selectedTime!,
                    status: "pending",
                  );

                  final error =
                      await appointmentRepo.bookAppointmentSafe(appointment);

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (error != null) {
                    _toast(error);
                  } else {
                    _toast("Booked successfully ✅");
                  }
                },
                child: const Text("Book"),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Widget _buildServicesTab() {
    return StreamBuilder<List<ServiceModel>>(
      stream: serviceRepo.streamActiveServices(),
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
              child: ListTile(
                title: Text(
                  s.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  "${s.price} LKR • ${s.duration} mins • ${s.category}",
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _bookService(s),
                  child: const Text("Book"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "User not found",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return StreamBuilder<List<AppointmentModel>>(
      stream: appointmentRepo.getUserAppointments(user.uid),
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

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const Center(
            child: Text(
              "No appointments yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final a = appointments[index];

            return Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(a.date)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Time: ${a.timeSlot}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Price: ${a.price} LKR",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Duration: ${a.duration} mins",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(a.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor(a.status)),
                      ),
                      child: Text(
                        a.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(a.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (a.status == 'pending') ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await appointmentRepo.cancelAppointment(a.id);
                            _toast("Appointment cancelled");
                          } catch (e) {
                            _toast("Cancel failed: $e");
                          }
                        },
                        child: const Text("Cancel Appointment"),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Text(
            "User Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            labelColor: _gold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: _gold,
            tabs: [
              Tab(text: "Services"),
              Tab(text: "My Appointments"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildServicesTab(),
            _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }
}