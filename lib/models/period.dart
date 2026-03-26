import 'activity.dart';

class Period {
  final String id;
  final int noPeriode;
  final int washCount;
  final int progressCycle;
  final List<Activity>? activities;

  Period({
    required this.id,
    required this.noPeriode,
    required this.washCount,
    required this.progressCycle,
    this.activities,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'].toString(),
      noPeriode: json['no_periode'] ?? json['no_periode_raw'] ?? 0, // Fallback if name mismatches
      washCount: json['wash_count'] ?? 0,
      progressCycle: json['progress_cycle'] ?? 0,
      activities: json['activities'] != null
          ? (json['activities'] as List).map((i) {
              try {
                return Activity.fromJson(i);
              } catch (e) {
                // Return null on failure, then filter out nulls
                return null;
              }
            }).whereType<Activity>().toList()
          : null,
    );
  }
}
