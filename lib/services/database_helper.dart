import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed database service with per-user data isolation.
/// Collections: vehicles, periods, activities, notifications
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────── VEHICLES ────────────────

  Future<List<Map<String, dynamic>>> getVehicles(String userId) async {
    final snapshot = await _db.collection('vehicles')
        .where('user_id', isEqualTo: userId)
        .get();
        
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final tA = a.data()['created_at'];
      final tB = b.data()['created_at'];
      final dateA = tA is Timestamp ? tA.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = tB is Timestamp ? tB.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      return dateA.compareTo(dateB);
    });
    
    return docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> createVehicle(String userId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('vehicles').add({
      'user_id': userId,
      'nama_kendaraan': data['nama_kendaraan'],
      'tipe': data['tipe'],
      'created_at': FieldValue.serverTimestamp(),
    });

    // Auto-create first period for the vehicle
    await _ensureActivePeriod(docRef.id);

    return {
      'id': docRef.id,
      'nama_kendaraan': data['nama_kendaraan'],
      'tipe': data['tipe'],
    };
  }

  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data) async {
    await _db.collection('vehicles').doc(id).update({
      'nama_kendaraan': data['nama_kendaraan'],
      'tipe': data['tipe'],
    });
    return {
      'id': id,
      'nama_kendaraan': data['nama_kendaraan'],
      'tipe': data['tipe'],
    };
  }

  Future<void> deleteVehicle(String id) async {
    // Delete related activities first
    final periods = await _db.collection('periods')
        .where('vehicle_id', isEqualTo: id).get();
    for (final periodDoc in periods.docs) {
      final activities = await _db.collection('activities')
          .where('period_id', isEqualTo: periodDoc.id).get();
      for (final actDoc in activities.docs) {
        await actDoc.reference.delete();
      }
      await periodDoc.reference.delete();
    }
    // Delete vehicle
    await _db.collection('vehicles').doc(id).delete();
  }

  // ──────────────── DASHBOARD ────────────────

  Future<Map<String, dynamic>> getDashboard(String vehicleId) async {
    final period = await _ensureActivePeriod(vehicleId);
    final periodId = period['id'] as String;
    final activities = await _getActivitiesForPeriod(periodId);

    int washCount = activities.where((a) => a['is_wash'] == true).length;

    // Find last wash
    String? lastWashText;
    int daysSinceLastWash = 0;
    bool isOverdue = false;

    final washes = activities.where((a) => a['is_wash'] == true).toList();
    if (washes.isNotEmpty) {
      washes.sort((a, b) {
        final dateA = _parseDate(a['created_at']);
        final dateB = _parseDate(b['created_at']);
        return dateB.compareTo(dateA);
      });
      final lastWashDate = _parseDate(washes.first['created_at']);
      daysSinceLastWash = DateTime.now().difference(lastWashDate).inDays;
      lastWashText = daysSinceLastWash == 0
          ? 'Dicuci hari ini'
          : 'Dicuci $daysSinceLastWash hari yang lalu';
      isOverdue = daysSinceLastWash > 7;
    }

    // Smart Alert
    String smartAlert = '';
    if (washCount == 2) {
      smartAlert = 'Waktunya Wax Bodi pada cuci berikutnya!';
    } else if (washCount == 5) {
      smartAlert = 'Waktunya Full Wax (Bodi & Kaca) pada cuci berikutnya!';
    } else if (isOverdue) {
      smartAlert = 'Mobil sudah lama tidak dicuci!';
    }

    return {
      'vehicle': {'id': vehicleId},
      'active_period': {
        'id': periodId,
        'no_periode': period['no_periode'],
        'wash_count': washCount,
        'progress_cycle': washCount > 6 ? 6 : washCount,
      },
      'last_wash_timer': {
        'text': lastWashText,
        'days': daysSinceLastWash,
        'is_overdue': isOverdue,
      },
      'smart_alert': smartAlert,
    };
  }

  // ──────────────── ACTIVITIES ────────────────

  Future<Map<String, dynamic>> recordActivity(String periodId, Map<String, dynamic> data) async {
    await _db.collection('activities').add({
      'period_id': periodId,
      'is_wash': data['is_wash'] ?? false,
      'is_wax_body': data['is_wax_body'] ?? false,
      'is_wax_glass': data['is_wax_glass'] ?? false,
      'is_vacuum': data['is_vacuum'] ?? false,
      'note': data['note'] ?? '',
      'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
    });

    // Check period reset (wash count >= 6)
    bool resetTriggered = false;
    if (data['is_wash'] == true) {
      final periodActivities = await _getActivitiesForPeriod(periodId);
      final washCount = periodActivities.where((a) => a['is_wash'] == true || a['is_wash'] == 1).length;

      if (washCount >= 6) {
        final periodDoc = await _db.collection('periods').doc(periodId).get();
        if (periodDoc.exists) {
          final vehicleId = periodDoc.data()!['vehicle_id'];
          final noPeriode = periodDoc.data()!['no_periode'] ?? 1;
          await _createPeriod(vehicleId, noPeriode + 1);
          resetTriggered = true;
        }
      }
    }

    return {
      'activity': {'id': 'new', ...data},
      'reset_triggered': resetTriggered,
    };
  }

  // ──────────────── HISTORY ────────────────

  Future<List<Map<String, dynamic>>> getHistory(String vehicleId) async {
    final periodsSnapshot = await _db.collection('periods')
        .where('vehicle_id', isEqualTo: vehicleId)
        .get();

    if (periodsSnapshot.docs.isEmpty) return [];

    final docs = periodsSnapshot.docs.toList();
    docs.sort((a, b) {
      final dataA = a.data();
      final dataB = b.data();
      
      int parsePeriod(dynamic val) {
        if (val is int) return val;
        if (val is String) return int.tryParse(val) ?? 0;
        return 0;
      }

      final noA = parsePeriod(dataA['no_periode']);
      final noB = parsePeriod(dataB['no_periode']);
      return noB.compareTo(noA); // descending
    });

    final List<Map<String, dynamic>> periods = docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();

    // Instead of using whereIn on period_ids which has a 30-item limit and requires indexes,
    // we fetch all activities for this vehicle by getting periods and mapping.
    // However, activities don't have vehicle_id. Since we know the periodIds:
    final periodIds = periods.map((p) => p['id'] as String).toList();
    final List<Map<String, dynamic>> allActivities = [];
    if (periodIds.isNotEmpty) {
      // Fetch all activities where period_id is in any of the periods
      // To bypass index errors and whereIn limits, we fetch them one by one or in batches.
      for (var i = 0; i < periodIds.length; i += 30) {
        final chunk = periodIds.sublist(i, i + 30 > periodIds.length ? periodIds.length : i + 30);
        final activitiesSnapshot = await _db.collection('activities')
            .where('period_id', whereIn: chunk)
            .get();
        allActivities.addAll(activitiesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}));
      }
    }

    final List<Map<String, dynamic>> result = [];
    debugPrint('Fetched ${periods.length} periods and ${allActivities.length} total activities for history');

    for (final period in periods) {
      final periodId = period['id'];
      final activities = allActivities.where((a) => a['period_id'] == periodId).toList();
      
      activities.sort((a, b) {
        final dateA = _parseDate(a['created_at']);
        final dateB = _parseDate(b['created_at']);
        return dateB.compareTo(dateA);
      });
      
      final formattedActivities = activities.map((a) {
        final d = _parseDate(a['created_at']);
        return {
          ...a,
          'created_at': d.toIso8601String(),
        };
      }).toList();

      result.add({
        'id': periodId,
        'no_periode': period['no_periode'],
        'wash_count': activities.where((a) => a['is_wash'] == true || a['is_wash'] == 1).length,
        'progress_cycle': activities.where((a) => a['is_wash'] == true || a['is_wash'] == 1).length,
        'activities': formattedActivities,
      });
    }

    debugPrint('Returning history result: ${result.length} cycles');
    return result;
  }

  // ──────────────── PRIVATE HELPERS ────────────────

  Future<Map<String, dynamic>> _ensureActivePeriod(String vehicleId) async {
    final periodsSnapshot = await _db.collection('periods')
        .where('vehicle_id', isEqualTo: vehicleId)
        .get();

    if (periodsSnapshot.docs.isEmpty) {
      return await _createPeriod(vehicleId, 1);
    }

    final docs = periodsSnapshot.docs.toList();
    docs.sort((a, b) {
      final noA = a.data()['no_periode'] as int? ?? 0;
      final noB = b.data()['no_periode'] as int? ?? 0;
      return noB.compareTo(noA); // descending
    });

    final latest = docs.first;
    final latestData = {'id': latest.id, ...latest.data()};

    // Check if period is full
    final activities = await _getActivitiesForPeriod(latest.id);
    final washCount = activities.where((a) => a['is_wash'] == true || a['is_wash'] == 1).length;

    if (washCount >= 6) {
      return await _createPeriod(vehicleId, (latestData['no_periode'] ?? 1) + 1);
    }

    return latestData;
  }

  Future<Map<String, dynamic>> _createPeriod(String vehicleId, int noPeriode) async {
    final docRef = await _db.collection('periods').add({
      'vehicle_id': vehicleId,
      'no_periode': noPeriode,
      'created_at': FieldValue.serverTimestamp(),
    });
    return {
      'id': docRef.id,
      'vehicle_id': vehicleId,
      'no_periode': noPeriode,
    };
  }

  Future<List<Map<String, dynamic>>> _getActivitiesForPeriod(String periodId) async {
    final snapshot = await _db.collection('activities')
        .where('period_id', isEqualTo: periodId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }
}
