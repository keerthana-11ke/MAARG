enum DispatchStatus { idle, notified, responding, arrived }

class HospitalLog {
  final String id;
  final String name;
  final double distance; // in kilometers
  final String contactNumber;
  final DispatchStatus status;
  final double latitude;
  final double longitude;

  HospitalLog({
    required this.id,
    required this.name,
    required this.distance,
    required this.contactNumber,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'distance': distance,
      'contactNumber': contactNumber,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory HospitalLog.fromMap(Map<String, dynamic> map, String documentId) {
    return HospitalLog(
      id: documentId,
      name: map['name'] ?? '',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      contactNumber: map['contactNumber'] ?? '',
      status: DispatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DispatchStatus.idle,
      ),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  HospitalLog copyWith({
    String? id,
    String? name,
    double? distance,
    String? contactNumber,
    DispatchStatus? status,
    double? latitude,
    double? longitude,
  }) {
    return HospitalLog(
      id: id ?? this.id,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
