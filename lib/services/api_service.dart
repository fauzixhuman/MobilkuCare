import '../models/vehicle.dart';
import 'database_helper.dart';

class ApiService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Vehicle>> getVehicles(String userId) async {
    final data = await _db.getVehicles(userId);
    return data.map((v) => Vehicle.fromJson(v)).toList();
  }

  Future<Map<String, dynamic>> getDashboard(String vehicleId) async {
    return await _db.getDashboard(vehicleId);
  }

  Future<Vehicle> createVehicle(String userId, Map<String, dynamic> data) async {
    final result = await _db.createVehicle(userId, data);
    return Vehicle.fromJson(result);
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async {
    final result = await _db.updateVehicle(id, data);
    return Vehicle.fromJson(result);
  }

  Future<void> deleteVehicle(String id) async {
    await _db.deleteVehicle(id);
  }

  Future<Map<String, dynamic>> recordActivity(String periodId, Map<String, dynamic> data) async {
    return await _db.recordActivity(periodId, data);
  }
}
