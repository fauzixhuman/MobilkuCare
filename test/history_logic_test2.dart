void main() {
  print('--- Starting DB Helper Isolation Test ---');

  final periods = [
    {
      'id': 'p1',
      'vehicle_id': 'v1',
      'no_periode': 1,
    },
    {
      'id': 'p2',
      'vehicle_id': 'v1',
      'no_periode': '2', // Legacy string
    }
  ];

  final allActivities = [
    {
      'id': 'a1',
      'period_id': 'p1',
      'is_wash': true,
      'is_wax_body': false,
      'is_wax_glass': false,
      'is_vacuum': false,
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'a2',
      'period_id': 'p2',
      'is_wash': 1, // Legacy integer boolean
      'is_wax_body': 0,
      'created_at': DateTime.now(), // Legacy direct datetime object
    }
  ];

  print('Raw Activities: \$allActivities');

  final List<Map<String, dynamic>> result = [];

  for (final period in periods) {
    print('Processing period \${period['id']}');
    final periodId = period['id'];
    final activities = allActivities.where((a) => a['period_id'] == periodId).toList();
    
    print('Found \${activities.length} activities for period \$periodId');

    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) return dateVal;
      if (dateVal is String) return DateTime.parse(dateVal);
      try {
        return (dateVal as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    activities.sort((a, b) {
      final dateA = parseDate(a['created_at']);
      final dateB = parseDate(b['created_at']);
      return dateB.compareTo(dateA);
    });
    
    final formattedActivities = activities.map((a) {
      final d = parseDate(a['created_at']);
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

  print('Result raw Map: \$result');

  try {
    for (var periodRaw in result) {
      final acts = periodRaw['activities'] as List;
      print('Mapping acts... count: \${acts.length}');
      for (var rawAct in acts) {
         try {
            print('Trying to parse activity: \$rawAct');
            final String id = rawAct['id'].toString();
            final bool isWash = rawAct['is_wash'] == 1 || rawAct['is_wash'] == true;
            final String createdAt = rawAct['created_at'].toString();
            final dt = DateTime.parse(createdAt);
            print('Parsed dt: \$dt, id: \$id, isWash: \$isWash');
         } catch(e) {
            print('Failed parsing activity: \$e \\n \$st');
         }
      }
    }
  } catch(e) {
    print('FATAL mapping Period: \$e \\n \$st');
  }

}
