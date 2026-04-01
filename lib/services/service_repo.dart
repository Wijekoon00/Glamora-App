import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('services');

  Stream<List<ServiceModel>> streamServices() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceModel.fromDoc(d))
              .toList(),
        );
  }

  Stream<List<ServiceModel>> streamActiveServices() {
    return _col
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceModel.fromDoc(d))
              .toList(),
        );
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ServiceModel.fromDoc(doc);
  }

  Future<void> addService({
    required String name,
    required num price,
    required int duration,
    required String category,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final service = ServiceModel(
      id: '',
      name: name.trim(),
      price: price,
      duration: duration,
      category: category.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      isActive: isActive,
    );

    await _col.add(service.toMapForCreate());
  }

  Future<void> updateService({
    required String id,
    required String name,
    required num price,
    required int duration,
    required String category,
    String? imageUrl,
    required bool isActive,
  }) async {
    final service = ServiceModel(
      id: id,
      name: name.trim(),
      price: price,
      duration: duration,
      category: category.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      isActive: isActive,
    );

    await _col.doc(id).update(service.toMapForUpdate());
  }

  Future<void> toggleServiceStatus({
    required String id,
    required bool isActive,
  }) async {
    await _col.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> deleteService(String id) async {
    await _col.doc(id).delete();
  }
}