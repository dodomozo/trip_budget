class TrashEntry {
  final String id;
  final String type; // 'expense' or 'trip'
  final String tripId;
  final DateTime deletedAt;
  final Map<String, dynamic> data;

  const TrashEntry({
    required this.id,
    required this.type,
    required this.tripId,
    required this.deletedAt,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'tripId': tripId,
      'deletedAt': deletedAt.toIso8601String(),
      'data': data,
    };
  }

  factory TrashEntry.fromJson(Map<String, dynamic> json) {
    return TrashEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      tripId: json['tripId'] as String,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
