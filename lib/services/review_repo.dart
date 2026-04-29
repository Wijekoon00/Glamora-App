import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reviews');

  Future<void> addReview(ReviewModel review) async {
    await _col.add(review.toMap());
  }

  Future<bool> hasReviewedAppointment(String appointmentId) async {
    final query = await _col
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<double> getAverageRating(String serviceId) async {
    final query = await _col
        .where('serviceId', isEqualTo: serviceId)
        .get();

    if (query.docs.isEmpty) return 0.0;

    double total = 0;

    for (final doc in query.docs) {
      final data = doc.data();
      total += ((data['rating'] ?? 0) as num).toDouble();
    }

    return total / query.docs.length;
  }

  Future<int> getReviewCount(String serviceId) async {
    final query = await _col
        .where('serviceId', isEqualTo: serviceId)
        .get();

    return query.docs.length;
  }

  Stream<List<ReviewModel>> getServiceReviews(String serviceId) {
    return _col
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReviewModel.fromDoc(d)).toList(),
        );
  }
}