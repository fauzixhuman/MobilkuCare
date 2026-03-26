import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mobilku_app/services/database_helper.dart';

void main() async {
  print('--- Starting DB Helper Isolation Test ---');
  final fakeDb = FakeFirebaseFirestore();

  // Inject fake db into Helper by passing it (we'll temporarily overwrite inside it)
  // Actually, wait, DatabaseHelper uses FirebaseFirestore.instance. For a quick unit test we can just copy
  // the getHistory logic here to see how type mapping handles raw Map data.

  // Simulate firestore periods
  final periods = [
    {
      'id': 'p1',
      'vehicle_id': 'v1',
      'no_periode': 1,
    }
  ];

  // Simulate firestore activities
  final allActivities = [
    {
      'id': 'a1',
      'period_id': 'p1',
      'is_wash': true,
      'is_wax_body': false,
      'is_wax_glass': false,
      'is_vacuum': false,
      'created_at': DateTime.now().toIso8601String(), // Typically a Timestamp in Firestore, but sometimes String
    }
  ];

  print('Raw Activities: \$allActivities');

  final List<Map<String, dynamic>> result = [];

  for (final period in periods) {
    print('Processing period \${period['id']}');
    final periodId = period['id'];
    final activities = allActivities.where((a) => a['period_id'] == periodId).toList();
    
    print('Found \${activities.length} activities for period \$periodId');

    // MOCK _parseDate logic
    DateTime _parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) return dateVal;
      // In Firestore, Timestamp has toDate() but in json it's String usually.
      if (dateVal is String) return DateTime.parse(dateVal);
      try {
        return (dateVal as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

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
      'wash_count': activities.where((a) => a['is_wash'] == true).length,
      'progress_cycle': activities.where((a) => a['is_wash'] == true).length,
      'activities': formattedActivities, // Ensure format is Map<String,dynamic>
    });
  }

  print('Result raw Map: \$result');

  // MOCK Period parsing to see if it dies here
  try {
    // Import your Period and Activity models
    // Since we can't easily import 'mobilku_app' outside web context easily without setup, we will just parse it
    // exactly like the Period.fromJson
    for (var periodRaw in result) {
      final acts = periodRaw['activities'] as List;
      print('Mapping acts... count: \${acts.length}');
      for (var rawAct in acts) {
         try {
            print('Trying to parse activity: \$rawAct');
            // Mock Activity.fromJson
            final String id = rawAct['id'].toString();
            final bool isWash = rawAct['is_wash'] == 1 || rawAct['is_wash'] == true;
            final String createdAt = rawAct['created_at'].toString();
            final dt = DateTime.parse(createdAt);
            print('Parsed dt: \$dt, id: \$id, isWash: \$isWash');
         } catch(e, st) {
            print('Failed parsing activity: \$e \\n \$st');
         }
      }
    }
  } catch(e, st) {
    print('FATAL mapping Period: \$e \\n \$st');
  }

}
