import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  Future<void> bookAppointment(AppointmentModel appointment) async {
    try {
      print("DEBUG: Saving appointment...");
      print(appointment.toMap());

      final docRef = await _col.add(appointment.toMap());

      print("DEBUG: Appointment saved with ID: ${docRef.id}");
    } catch (e) {
      print("DEBUG: bookAppointment error: $e");
      rethrow;
    }
  }

  Future<bool> isSlotAvailable({
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print("DEBUG: Checking slot availability...");
      print("DEBUG: Date = $date");
      print("DEBUG: TimeSlot = $timeSlot");

      final query = await _col
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      print("DEBUG: Matching appointments found = ${query.docs.length}");

      return query.docs.isEmpty;
    } catch (e) {
      print("DEBUG: isSlotAvailable error: $e");
      rethrow;
    }
  }

  Future<String?> bookAppointmentSafe(AppointmentModel appointment) async {
    try {
      final available = await isSlotAvailable(
        date: appointment.date,
        timeSlot: appointment.timeSlot,
      );

      if (!available) {
        return "This time slot is already booked";
      }

      final docRef = await _col.add(appointment.toMap());
      print("DEBUG: Safe booking saved with ID: ${docRef.id}");

      return null;
    } catch (e) {
      print("DEBUG: bookAppointmentSafe error: $e");
      return "Booking failed: $e";
    }
  }

  Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppointmentModel.fromDoc(d)).toList());
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppointmentModel.fromDoc(d)).toList());
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({'status': status});
  }

  Future<void> cancelAppointment(String id) async {
    await _col.doc(id).update({'status': 'cancelled'});
  }

  Future<void> deleteAppointment(String id) async {
    await _col.doc(id).delete();
  }
}