import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String appointmentId;
  final String serviceId;
  final String serviceName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.appointmentId,
    required this.serviceId,
    required this.serviceName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'appointmentId': appointmentId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}