enum BystanderRoleType { call, traffic, assist }
enum RoleStatus { open, occupied, completed }

class BystanderRole {
  final String id;
  final String incidentId;
  final BystanderRoleType roleType;
  final RoleStatus status;
  final String? userId; // Anonymous user ID of the person who claimed the role

  BystanderRole({
    required this.id,
    required this.incidentId,
    required this.roleType,
    required this.status,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'roleType': roleType.name,
      'status': status.name,
      'userId': userId,
    };
  }

  factory BystanderRole.fromMap(Map<String, dynamic> map, String documentId) {
    return BystanderRole(
      id: documentId,
      incidentId: map['incidentId'] ?? '',
      roleType: BystanderRoleType.values.firstWhere(
        (e) => e.name == map['roleType'],
        orElse: () => BystanderRoleType.call,
      ),
      status: RoleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoleStatus.open,
      ),
      userId: map['userId'],
    );
  }

  BystanderRole copyWith({
    String? id,
    String? incidentId,
    BystanderRoleType? roleType,
    RoleStatus? status,
    String? userId,
  }) {
    return BystanderRole(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      roleType: roleType ?? this.roleType,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}
