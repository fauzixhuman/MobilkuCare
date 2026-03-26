import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _userId = '';
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  Map<String, dynamic>? _dashboardData;
  bool suppressWashReminder = false;
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String get userId => _userId;

  bool _forceReminder = false;
  bool get forceReminder => _forceReminder;

  void requestReminder() {
    _forceReminder = true;
    notifyListeners();
  }

  void consumeReminder() {
    _forceReminder = false;
  }

  /// Called from AuthGate when user logs in
  void setUserId(String uid) {
    if (_userId == uid) return; // Avoid re-fetching if same user
    _userId = uid;
    _vehicles = [];
    _selectedVehicle = null;
    _dashboardData = null;
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    if (_userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _vehicles = await _apiService.getVehicles(_userId);
      if (_vehicles.isNotEmpty && _selectedVehicle == null) {
        _selectedVehicle = _vehicles.first;
        await _fetchDashboardDataInternal(); // Use internal method without extra notifications
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectVehicle(Vehicle vehicle) async {
    _selectedVehicle = vehicle;
    await fetchDashboardData();
  }

  Future<void> createVehicle(String nama, String tipe) async {
    if (_userId.isEmpty) return;

    try {
      final newVehicle = await _apiService.createVehicle(_userId, {
        'nama_kendaraan': nama,
        'tipe': tipe,
      });
      _vehicles.add(newVehicle);
      suppressWashReminder = true;
      if (_selectedVehicle == null) {
        selectVehicle(newVehicle);
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error creating vehicle: $e');
      rethrow;
    }
  }

  Future<void> updateVehicle(String id, String nama, String tipe) async {
    try {
      final updatedVehicle = await _apiService.updateVehicle(id, {
        'nama_kendaraan': nama,
        'tipe': tipe,
      });
      
      final index = _vehicles.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        
        if (_selectedVehicle?.id == id) {
          _selectedVehicle = updatedVehicle;
          await fetchDashboardData();
        } else {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _apiService.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      
      if (_selectedVehicle?.id == id) {
        _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
        if (_selectedVehicle != null) {
          await fetchDashboardData();
        } else {
          _dashboardData = null;
          notifyListeners();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      rethrow;
    }
  }

  Future<void> fetchDashboardData() async {
    if (_selectedVehicle == null) return;
    
    _isLoading = true;
    notifyListeners();

    await _fetchDashboardDataInternal();

    _isLoading = false;
    notifyListeners();
  }

  /// Internal implementation to avoid redundant notifyListeners when called from other methods
  Future<void> _fetchDashboardDataInternal() async {
    if (_selectedVehicle == null) return;
    try {
      _dashboardData = await _apiService.getDashboard(_selectedVehicle!.id);
      _checkAndNotifyWashMilestone();
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    }
  }

  /// Check if wash count is at a milestone and send notification
  void _checkAndNotifyWashMilestone() {
    if (_dashboardData == null || _dashboardData!['active_period'] == null) return;
    
    final washCount = _dashboardData!['active_period']['wash_count'] as int;

    if (washCount == 2) {
      NotificationService().showNotification(
        id: 3,
        title: 'Waktunya Wax Bodi! 🧴',
        body: 'Cuci berikutnya adalah cuci ke-3. Jangan lupa aplikasikan wax pada bodi mobil!',
        userId: _userId,
      );
    } else if (washCount == 5) {
      NotificationService().showNotification(
        id: 6,
        title: 'Waktunya Full Wax! ✨',
        body: 'Cuci berikutnya adalah cuci ke-6. Waktunya wax seluruh bodi dan kaca!',
        userId: _userId,
      );
    }
  }

  Future<void> recordActivity(Map<String, dynamic> data) async {
    if (_dashboardData == null || _dashboardData!['active_period'] == null) return;
    
    try {
      String periodId = _dashboardData!['active_period']['id'];
      final result = await _apiService.recordActivity(periodId, data);
      
      // Handle Local notifications based on wash count
      if (data['is_wash'] == true) {
        int newWashCount = _dashboardData!['active_period']['wash_count'] + 1;
        
        if (newWashCount == 3) {
           await NotificationService().showNotification(
             id: 3, 
             title: 'Waktunya Wax Bodi', 
             body: 'Mobil Anda sudah dicuci 3 kali. Saatnya mengaplikasikan wax pada bodi mobil!',
             userId: _userId,
           );
        } else if (result['reset_triggered'] == true) {
           await NotificationService().showNotification(
             id: 6, 
             title: 'Waktunya Full Wax', 
             body: 'Siklus cuci ke-6 selesai! Waktunya wax seluruh bodi dan kaca.',
             userId: _userId,
           );
        }
      }

      await fetchDashboardData(); // Refresh data after recording
    } catch (e) {
      debugPrint('Error recording activity: $e');
      rethrow;
    }
  }

  /// Reset state when user logs out
  void clearData() {
    _userId = '';
    _vehicles = [];
    _selectedVehicle = null;
    _dashboardData = null;
    notifyListeners();
  }
}
