import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String serviceId;
  final String serviceName;
  final num price;
  final int duration;
  final DateTime date;
  final String timeSlot;
  final String status;
  final DateTime? createdAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.createdAt,
  });

  factory AppointmentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppointmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      price: data['price'] ?? 0,
      duration: data['duration'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

Map<String, dynamic> toMap() {
  return {
    'userId': userId,
    'userName': userName,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'price': price,
    'duration': duration,
    'date': Timestamp.fromDate(date),
    'timeSlot': timeSlot,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
}