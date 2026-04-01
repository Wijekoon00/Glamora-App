import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final num price;
  final int duration; // minutes
  final String category; // hair, beard, facial, etc.
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.category,
    this.imageUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ServiceModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      price: (data['price'] ?? 0) as num,
      duration: (data['duration'] ?? 0) as int,
      category: (data['category'] ?? '').toString(),
      imageUrl: data['imageUrl']?.toString(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'name': name,
      'price': price,
      'duration': duration,
      'category': category,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'price': price,
      'duration': duration,
      'category': category,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}