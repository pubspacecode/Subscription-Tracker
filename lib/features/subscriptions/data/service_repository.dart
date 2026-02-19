import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/hive_service.dart';
import 'service_model.dart'; // Correct relative import

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(HiveService.servicesBox);
});

class ServiceRepository {
  final Box<ServiceModel> _box;

  ServiceRepository(this._box);

  List<ServiceModel> getAllServices() {
    return _box.values.toList();
  }

  List<ServiceModel> searchServices(String query) {
    if (query.isEmpty) return getAllServices();
    return _box.values.where((service) {
      return service.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
