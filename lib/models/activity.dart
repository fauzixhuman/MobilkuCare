class Activity {
  final String id;
  final bool isWash;
  final bool isWaxBody;
  final bool isWaxGlass;
  final bool isVacuum;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.isWash,
    required this.isWaxBody,
    required this.isWaxGlass,
    required this.isVacuum,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } catch (e) {
      parsedDate = DateTime.now(); // Fallback to current time if unparseable
    }

    return Activity(
      id: json['id'].toString(),
      isWash: json['is_wash'] == 1 || json['is_wash'] == true,
      isWaxBody: json['is_wax_body'] == 1 || json['is_wax_body'] == true,
      isWaxGlass: json['is_wax_glass'] == 1 || json['is_wax_glass'] == true,
      isVacuum: json['is_vacuum'] == 1 || json['is_vacuum'] == true,
      createdAt: parsedDate,
    );
  }
}
