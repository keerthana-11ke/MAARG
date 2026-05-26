import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentStatus { active, resolved }

class Incident {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final IncidentStatus status;

  Incident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, String documentId) {
    return Incident(
      id: documentId,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => IncidentStatus.active,
      ),
    );
  }

  Incident copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    IncidentStatus? status,
  }) {
    return Incident(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
