import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _col.add(appointment.toMap());
  }

  Future<List<String>> getBookedTimeSlots(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    return query.docs
        .map((doc) => (doc.data()['timeSlot'] ?? '').toString())
        .where((slot) => slot.isNotEmpty)
        .toList();
  }

  Future<bool> isSlotAvailable({
    required DateTime date,
    required String timeSlot,
  }) async {
    final bookedSlots = await getBookedTimeSlots(date);
    return !bookedSlots.contains(timeSlot);
  }

  Future<String?> bookAppointmentSafe(AppointmentModel appointment) async {
    final available = await isSlotAvailable(
      date: appointment.date,
      timeSlot: appointment.timeSlot,
    );

    if (!available) {
      return "This time slot is already booked";
    }

    await _col.add(appointment.toMap());
    return null;
  }

  Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AppointmentModel.fromDoc(d)).toList(),
        );
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _col
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AppointmentModel.fromDoc(d)).toList(),
        );
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({'status': status});
  }

  Future<void> approveAppointment(String id) async {
    await updateStatus(id, 'approved');
  }

  Future<void> completeAppointment(String id) async {
    await updateStatus(id, 'completed');
  }

  Future<void> cancelAppointment(String id) async {
    await updateStatus(id, 'cancelled');
  }

  Future<void> deleteAppointment(String id) async {
    await _col.doc(id).delete();
  }
}