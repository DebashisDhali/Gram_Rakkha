class UserEntity {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? communityId;
  final double? homeLat;
  final double? homeLng;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.communityId,
    this.homeLat,
    this.homeLng,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      communityId: json['community_id'],
      homeLat: json['home_lat'],
      homeLng: json['home_lng'],
    );
  }
}

class AlertEntity {
  final String id;
  final String reporterId;
  final String reporterName;
  final String type;
  final String status;
  final double lat;
  final double lng;
  final DateTime timestamp;

  AlertEntity({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.type,
    required this.status,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory AlertEntity.fromJson(Map<String, dynamic> json) {
    return AlertEntity(
      id: json['id'],
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'] ?? 'Unknown',
      type: json['type'],
      status: json['status'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
