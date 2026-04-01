import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _col.add(appointment.toMap());
  }

  Future<bool> isSlotAvailable({
    required DateTime date,
    required String timeSlot,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('timeSlot', isEqualTo: timeSlot)
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    return query.docs.isEmpty;
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
          (snap) => snap.docs
              .map((d) => AppointmentModel.fromDoc(d))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppointmentModel.fromDoc(d))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getAppointmentsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppointmentModel.fromDoc(d))
              .toList(),
        );
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
    });
  }

  Future<void> cancelAppointment(String id) async {
    await _col.doc(id).update({
      'status': 'cancelled',
    });
  }

  Future<void> deleteAppointment(String id) async {
    await _col.doc(id).delete();
  }
}