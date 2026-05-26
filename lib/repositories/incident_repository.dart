import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/incident.dart';
import '../models/bystander_role.dart';
import '../models/hospital_log.dart';

abstract class IncidentRepository {
  Future<Incident> createIncident(double latitude, double longitude);
  Future<void> resolveIncident(String incidentId);
  Stream<Incident?> listenToIncident(String incidentId);
  Stream<List<BystanderRole>> listenToRoles(String incidentId);
  Future<void> claimRole(String incidentId, String roleId, String userId);
  Future<void> releaseRole(String incidentId, String roleId);
  Future<void> completeRole(String incidentId, String roleId);
  Stream<List<HospitalLog>> listenToHospitalLogs(String incidentId);
  Future<void> updateHospitalLogStatus(String incidentId, String logId, DispatchStatus status);
}

class MockIncidentRepository implements IncidentRepository {
  Incident? _currentIncident;
  final List<BystanderRole> _currentRoles = [];
  final List<HospitalLog> _currentLogs = [];

  final _incidentController = StreamController<Incident?>.broadcast();
  final _rolesController = StreamController<List<BystanderRole>>.broadcast();
  final _logsController = StreamController<List<HospitalLog>>.broadcast();
  
  Timer? _simulationTimer;

  MockIncidentRepository() {
    _incidentController.add(null);
    _rolesController.add([]);
    _logsController.add([]);
  }

  @override
  Future<Incident> createIncident(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate networking
    final incidentId = const Uuid().v4();
    
    _currentIncident = Incident(
      id: incidentId,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      status: IncidentStatus.active,
    );

    _currentRoles.clear();
    _currentRoles.addAll([
      BystanderRole(id: 'role_call', incidentId: incidentId, roleType: BystanderRoleType.call, status: RoleStatus.open),
      BystanderRole(id: 'role_traffic', incidentId: incidentId, roleType: BystanderRoleType.traffic, status: RoleStatus.open),
      BystanderRole(id: 'role_assist', incidentId: incidentId, roleType: BystanderRoleType.assist, status: RoleStatus.open),
    ]);

    _currentLogs.clear();
    _currentLogs.addAll([
      HospitalLog(
        id: 'log_stjude',
        name: 'St. Jude Emergency Center',
        distance: 1.8,
        contactNumber: '102', // Standard emergency code in India
        status: DispatchStatus.idle,
        latitude: latitude + 0.008,
        longitude: longitude - 0.01,
      ),
      HospitalLog(
        id: 'log_citygen',
        name: 'City General Trauma Care',
        distance: 3.4,
        contactNumber: '102',
        status: DispatchStatus.idle,
        latitude: latitude - 0.015,
        longitude: longitude + 0.012,
      ),
    ]);

    _updateStreams();

    // Start simulation of emergency responses
    _startDispatchSimulation(incidentId);

    return _currentIncident!;
  }

  void _startDispatchSimulation(String incidentId) {
    _simulationTimer?.cancel();
    
    // Step 1: Notify services after 4 seconds
    _simulationTimer = Timer(const Duration(seconds: 4), () {
      if (_currentIncident?.id != incidentId) return;
      _currentLogs[0] = _currentLogs[0].copyWith(status: DispatchStatus.notified);
      _updateStreams();
      
      // Step 2: Responder dispatched after 8 seconds
      _simulationTimer = Timer(const Duration(seconds: 4), () {
        if (_currentIncident?.id != incidentId) return;
        _currentLogs[0] = _currentLogs[0].copyWith(status: DispatchStatus.responding);
        _currentLogs[1] = _currentLogs[1].copyWith(status: DispatchStatus.notified);
        _updateStreams();

        // Step 3: First arrival after 16 seconds
        _simulationTimer = Timer(const Duration(seconds: 8), () {
          if (_currentIncident?.id != incidentId) return;
          _currentLogs[0] = _currentLogs[0].copyWith(status: DispatchStatus.arrived);
          _currentLogs[1] = _currentLogs[1].copyWith(status: DispatchStatus.responding);
          _updateStreams();
        });
      });
    });
  }

  void _updateStreams() {
    _incidentController.add(_currentIncident);
    _rolesController.add(List.from(_currentRoles));
    _logsController.add(List.from(_currentLogs));
  }

  @override
  Future<void> resolveIncident(String incidentId) async {
    if (_currentIncident?.id == incidentId) {
      _currentIncident = _currentIncident!.copyWith(status: IncidentStatus.resolved);
      _simulationTimer?.cancel();
      _updateStreams();
    }
  }

  @override
  Stream<Incident?> listenToIncident(String incidentId) => _incidentController.stream;

  @override
  Stream<List<BystanderRole>> listenToRoles(String incidentId) => _rolesController.stream;

  @override
  Future<void> claimRole(String incidentId, String roleId, String userId) async {
    final idx = _currentRoles.indexWhere((r) => r.id == roleId);
    if (idx != -1) {
      _currentRoles[idx] = _currentRoles[idx].copyWith(status: RoleStatus.occupied, userId: userId);
      _updateStreams();
    }
  }

  @override
  Future<void> releaseRole(String incidentId, String roleId) async {
    final idx = _currentRoles.indexWhere((r) => r.id == roleId);
    if (idx != -1) {
      _currentRoles[idx] = BystanderRole(
        id: roleId,
        incidentId: incidentId,
        roleType: _currentRoles[idx].roleType,
        status: RoleStatus.open,
        userId: null,
      );
      _updateStreams();
    }
  }

  @override
  Future<void> completeRole(String incidentId, String roleId) async {
    final idx = _currentRoles.indexWhere((r) => r.id == roleId);
    if (idx != -1) {
      _currentRoles[idx] = _currentRoles[idx].copyWith(status: RoleStatus.completed);
      _updateStreams();
    }
  }

  @override
  Stream<List<HospitalLog>> listenToHospitalLogs(String incidentId) => _logsController.stream;

  @override
  Future<void> updateHospitalLogStatus(String incidentId, String logId, DispatchStatus status) async {
    final idx = _currentLogs.indexWhere((l) => l.id == logId);
    if (idx != -1) {
      _currentLogs[idx] = _currentLogs[idx].copyWith(status: status);
      _updateStreams();
    }
  }
}
