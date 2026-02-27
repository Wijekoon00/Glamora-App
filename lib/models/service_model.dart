class ServiceModel {
  final String id;
  final String name;
  final int price;
  final int duration;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  factory ServiceModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      duration: data['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'duration': duration,
    };
  }
}