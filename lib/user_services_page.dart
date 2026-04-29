import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/service_model.dart';
import 'models/appointment_model.dart';
import 'services/service_repo.dart';
import 'services/appointment_repo.dart';
import 'services/review_repo.dart';
import 'widgets/luxury_form_widgets.dart';

class UserServicesPage extends StatefulWidget {
  const UserServicesPage({super.key});

  @override
  State<UserServicesPage> createState() => _UserServicesPageState();
}

class _UserServicesPageState extends State<UserServicesPage> {
  final serviceRepo = ServiceRepo();
  final appointmentRepo = AppointmentRepo();
  final reviewRepo = ReviewRepo();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: LuxuryTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LuxuryTheme.purple.withAlpha(80)),
        ),
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
      final userName =
          (userData['name'] ?? user.displayName ?? user.email ?? "Customer")
              .toString();

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

      final result = await appointmentRepo.bookAppointmentSafe(appointment);

      if (result != null) {
        _toast(result);
      } else {
        _toast("Appointment booked successfully ✅");
      }
    } catch (e) {
      _toast("Booking failed");
    }
  }

  Future<void> _bookService(ServiceModel service) async {
    if (!service.isActive) {
      _toast("This service is currently unavailable");
      return;
    }

    DateTime? selectedDate;
    String? selectedTime;
    List<String> bookedSlots = [];
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
          Future<void> pickDate() async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              initialDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: LuxuryTheme.purpleLight,
                      onPrimary: Colors.white,
                      surface: LuxuryTheme.card,
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: LuxuryTheme.card,
                  ),
                  child: child!,
                );
              },
            );

            if (date != null) {
              setStateDialog(() {
                selectedDate = date;
                selectedTime = null;
                bookedSlots = [];
              });

              _toast("Loading available slots...");

              try {
                final slots = await appointmentRepo.getBookedTimeSlots(date);
                setStateDialog(() {
                  bookedSlots = slots;
                });
              } catch (e) {
                _toast("Loading slots... please wait ⏳");
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              decoration: BoxDecoration(
                color: LuxuryTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: LuxuryTheme.purple.withAlpha(60),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LuxuryTheme.purple.withAlpha(40),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Dialog header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: LuxuryTheme.purple.withAlpha(40),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LuxuryTheme.purple,
                                LuxuryTheme.purpleLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Book ${service.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Dialog body ────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Select Date button
                          GestureDetector(
                            onTap: pickDate,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    LuxuryTheme.purple,
                                    LuxuryTheme.purpleLight,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: LuxuryTheme.purple.withAlpha(100),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedDate == null
                                        ? "Select Date"
                                        : "Change Date",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Selected date display
                          if (selectedDate != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: LuxuryTheme.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy')
                                      .format(selectedDate!),
                                  style: const TextStyle(
                                    color: LuxuryTheme.gold,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Time slot label
                          const Text(
                            "Select Time Slot",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Time slot chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timeSlots.map((slot) {
                              final isBooked = bookedSlots.contains(slot);
                              final isSelected = selectedTime == slot;

                              return GestureDetector(
                                onTap: (selectedDate == null || isBooked)
                                    ? null
                                    : () {
                                        setStateDialog(() {
                                          selectedTime = slot;
                                        });
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              LuxuryTheme.purple,
                                              LuxuryTheme.purpleLight,
                                            ],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : isBooked
                                            ? Colors.red.withAlpha(46)
                                            : const Color(0xFF0A0A14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isBooked
                                          ? Colors.redAccent
                                          : isSelected
                                              ? LuxuryTheme.purpleLight
                                              : LuxuryTheme.purple
                                                  .withAlpha(120),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: LuxuryTheme.purple
                                                  .withAlpha(80),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      color: isBooked
                                          ? Colors.redAccent
                                          : isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),

                          // Helper text
                          if (selectedDate == null)
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white.withAlpha(100),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Please select a date first",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(100),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          if (selectedDate != null)
                            Row(
                              children: const [
                                Icon(
                                  Icons.circle,
                                  color: Colors.redAccent,
                                  size: 8,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Red slots are already booked",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Dialog actions ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: LuxuryTheme.purple.withAlpha(40),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: GestureDetector(
                            onTap: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withAlpha(30),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Book
                        Expanded(
                          child: GestureDetector(
                            onTap: isSaving
                                ? null
                                : () async {
                                    if (selectedDate == null ||
                                        selectedTime == null) {
                                      _toast("Select date and time");
                                      return;
                                    }

                                    if (bookedSlots.contains(selectedTime)) {
                                      _toast(
                                          "This time slot is already booked");
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

                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: isSaving
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          LuxuryTheme.purple,
                                          LuxuryTheme.purpleLight,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                color: isSaving ? Colors.grey.shade700 : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isSaving
                                    ? null
                                    : [
                                        BoxShadow(
                                          color:
                                              LuxuryTheme.purple.withAlpha(100),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Book Now",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            ? Colors.green.withAlpha(38)
            : Colors.red.withAlpha(38),
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

  Widget _pillBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LuxuryTheme.purpleDim.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuxuryTheme.purple.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LuxuryTheme.purpleLight, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryLabel(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LuxuryTheme.purple.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: LuxuryTheme.purpleLight.withAlpha(200),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _ratingWidget(String serviceId) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        reviewRepo.getAverageRating(serviceId),
        reviewRepo.getReviewCount(serviceId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            "Rating: Loading...",
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
          );
        }

        final avg = snapshot.data![0] as double;
        final count = snapshot.data![1] as int;

        if (count == 0) {
          return Text(
            "No ratings yet",
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
          );
        }

        return Row(
          children: [
            const Icon(Icons.star_rounded, color: LuxuryTheme.gold, size: 18),
            const SizedBox(width: 4),
            Text(
              "${avg.toStringAsFixed(1)} ($count reviews)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LuxuryTheme.black,
      child: StreamBuilder<List<ServiceModel>>(
        stream: serviceRepo.streamServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: LuxuryTheme.purpleLight,
              ),
            );
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: LuxuryTheme.purpleDim.withAlpha(180),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LuxuryTheme.purple.withAlpha(80),
                      ),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: LuxuryTheme.purpleLight,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No services available",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Check back soon",
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = services[index];

              return Container(
                decoration: BoxDecoration(
                  color: LuxuryTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: LuxuryTheme.purple.withAlpha(60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryTheme.purple.withAlpha(25),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: name + category ───────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _categoryLabel(s.category),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Price + Duration pills ─────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pillBadge(
                            icon: Icons.attach_money_rounded,
                            label: "${s.price} LKR",
                          ),
                          _pillBadge(
                            icon: Icons.timer_rounded,
                            label: "${s.duration} mins",
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Rating ─────────────────────────────────────────
                      _ratingWidget(s.id),
                      const SizedBox(height: 12),

                      // ── Status chip ────────────────────────────────────
                      _statusChip(s.isActive),
                      const SizedBox(height: 16),

                      // ── Book Now button ────────────────────────────────
                      GestureDetector(
                        onTap: s.isActive ? () => _bookService(s) : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: s.isActive
                                ? const LinearGradient(
                                    colors: [
                                      LuxuryTheme.purple,
                                      LuxuryTheme.purpleLight,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: s.isActive ? null : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: s.isActive
                                ? [
                                    BoxShadow(
                                      color: LuxuryTheme.purple.withAlpha(100),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              s.isActive ? "Book Now" : "Unavailable",
                              style: TextStyle(
                                color: s.isActive
                                    ? Colors.white
                                    : Colors.white38,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
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
